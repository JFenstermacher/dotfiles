-- hooks/backend_install.lua
-- BackendInstall: downloads, verifies, and extracts a shipyard binary release.
--
-- shipyard stores each artifact at the public R2 read URL under the
-- deterministic key `artifacts/<tool>/<version>/<filename>`, with a
-- `<filename>.sha256` sidecar publishing its digest. Published binaries (see
-- terraform-provider-mimiskelda) follow `<tool>_<version>_<os>_<arch>.zip`:
--
--   <base_url>/artifacts/<tool>/<version>/<tool>_<version>_<os>_<arch>.zip
--
-- Configuration (ctx.options, as declared per tool in mise.toml):
--   * base_url    — shipyard public read base URL (no trailing slash).
--     Defaults to `MIMISKELDA_PUBLIC_BASE_URL` env, else the production
--     shipyard r2.dev domain.
--   * os / arch   — override the platform tokens used in the artifact
--     filename (default derives from the runtime, e.g. "darwin" / "arm64").
--   * filename    — exact artifact filename, bypassing the default
--     `<tool>_<version>_<os>_<arch>.zip` pattern.
--   * binary_name — the executable's on-disk name (also its in-archive
--     name); defaults to the tool name.
--   * verify      — verify the bytes against the published `.sha256` sidecar
--     (default true; warn and continue when no checksum tool/sidecar is
--     available).
--   * strip       — `archiver.decompress` strip_components guess (default 1,
--     then falls back to 0).
--
-- @param ctx {tool, version, install_path, download_path, options}
-- @return {} on success; raises on unrecoverable failure.

local archiver = require("archiver")
local cmd = require("cmd")
local file = require("file")
local http = require("http")
local log = require("log")
local strings = require("strings")

-- Production public read base URL for the shipyard bucket (r2.dev managed
-- domain; matches rig's DefaultPublicBaseURL).
local DEFAULT_BASE_URL = "https://pub-190648604aa244df91d83ed8417a33ba.r2.dev"

--- Lowers a runtime platform token to a stable artifact-name token.
local function normalize_os(raw)
    return (raw or ""):lower()
end

--- Finds the first file named `name` under `root` using the platform `find`
-- CLI (the file module at this mise version exposes no list/glob).
-- Returns the full path (first match, line-trimmed) or nil.
local function find_named_file(root, name)
    local ok, out = pcall(cmd.exec, 'find "' .. root .. '" -type f -name "' .. name .. '"')
    if not ok or type(out) ~= "string" or out == "" then
        return nil
    end
    local first = out:match("^%s*([^\n]-)%s*$")
    if not first or first == "" then
        return nil
    end
    return first
end

--- Decompresses `archive` into `stage`, trying strip_components = `preferred`
-- then 0, and returns the full path of the named binary.
local function extract_up_to_binary(archive, stage, binary_name, preferred)
    os.execute("mkdir -p '" .. stage .. "'")
    for _, components in ipairs({ preferred or 1, 0 }) do
        local ok = pcall(archiver.decompress, archive, stage, { strip_components = components })
        if ok then
            local found = find_named_file(stage, binary_name)
            if found then
                return found
            end
        end
    end
    error(
        "mimiskelda: extracted "
            .. binary_name
            .. " but no file named '"
            .. binary_name
            .. "' was found in the archive"
    )
end

function PLUGIN:BackendInstall(ctx)
    local tool = ctx.tool
    local version = ctx.version
    local install_path = ctx.install_path
    local opts = ctx.options or {}

    if not tool or tool == "" then
        error("mimiskelda: tool name cannot be empty")
    end
    if not version or version == "" then
        error("mimiskelda: version cannot be empty")
    end
    if not install_path or install_path == "" then
        error("mimiskelda: install_path cannot be empty")
    end

    -- Resolve base URL: option > env > production default.
    local base_url = opts.base_url
    if not base_url or base_url == "" then
        base_url = os.getenv("MIMISKELDA_PUBLIC_BASE_URL")
    end
    if not base_url or base_url == "" then
        base_url = DEFAULT_BASE_URL
    end

    -- Platform tokens for artifact naming (option overrides the runtime).
    local os_token = normalize_os(opts.os or RUNTIME.osType)
    local arch_token = opts.arch or RUNTIME.archType
    local binary_name = opts.binary_name or tool

    -- Artifact filename (explicit override else the established shipyard
    -- convention `<tool>_<version>_<os>_<arch>.zip`, matching published
    -- terraform-provider-mimiskelda binaries).
    local filename = opts.filename
    if not filename or filename == "" then
        filename = tool .. "_" .. version .. "_" .. os_token .. "_" .. arch_token .. ".zip"
    end

    local key = "artifacts/" .. tool .. "/" .. version .. "/" .. filename
    local download_url = base_url .. "/" .. key
    local archive_path = file.join_path(ctx.download_path, filename)

    log.info("mimiskelda: downloading", download_url)
    local _, err = http.try_download_file(
        { url = download_url, headers = { ["User-Agent"] = "mise-mimiskelda-plugin" } },
        archive_path
    )
    if err ~= nil then
        error("mimiskelda: download failed: " .. tostring(err))
    end
    if not file.exists(archive_path) then
        error("mimiskelda: downloaded file not found at " .. archive_path)
    end

    -- SHA-256 sidecar verification.
    local verify = true
    if opts.verify ~= nil then
        verify = opts.verify
    end
    if verify then
        local sresp, serr = http.try_get({ url = download_url .. ".sha256" })
        local expected = nil
        if serr == nil and sresp.status_code == 200 then
            expected = strings.trim_space(sresp.body or "")
        end
        if expected and expected ~= "" then
            local ok, out = pcall(cmd.exec, 'shasum -a 256 "' .. archive_path .. '"')
            if not ok then
                ok, out = pcall(cmd.exec, 'sha256sum "' .. archive_path .. '"')
            end
            local actual = type(out) == "string" and out:match("%x+") or nil
            if actual and actual:lower() ~= expected:lower() then
                error(
                    "mimiskelda: SHA-256 mismatch for "
                        .. filename
                        .. " (expected "
                        .. expected:lower()
                        .. ", got "
                        .. actual:lower()
                        .. ")"
                )
            end
            log.info("mimiskelda: sha256 verified", actual:lower())
        else
            log.warn("mimiskelda: no sha256 sidecar found; verification skipped")
        end
    end

    -- Extract the binary into install_path and make it executable. The file
    -- module at runtime has no move API at this mise version; use the shell.
    os.execute("mkdir -p '" .. install_path .. "'")
    local stage = file.join_path(ctx.download_path, "extract")
    local binary = extract_up_to_binary(archive_path, stage, binary_name, opts.strip or 1)
    local dest = file.join_path(install_path, binary_name)
    os.execute("mv -f '" .. binary .. "' '" .. dest .. "'")
    os.execute("chmod +x '" .. dest .. "'")

    log.info("mimiskelda: installed", tool, version, "to", dest)
    return {}
end