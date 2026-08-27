-- hooks/backend_install.lua
-- BackendInstall: downloads, verifies, and extracts a nidavellir binary release.
--
-- nidavellir stores each artifact at the public R2 read URL under the
-- deterministic key `artifacts/<tool>/<version>/<filename>`, with a
-- `<filename>.sha256` sidecar publishing its digest. Published binaries (see
-- terraform-provider-mimiskelda) follow `<tool>_<version>_<os>_<arch>.zip`:
--
--   <base_url>/artifacts/<tool>/<version>/<tool>_<version>_<os>_<arch>.zip
--
-- Configuration (ctx.options, as declared per tool in mise.toml):
--   * base_url    — nidavellir public read base URL (no trailing slash).
--     Defaults to `MIMISKELDA_PUBLIC_BASE_URL` env, else the production
--     nidavellir.mimiskelda.dev custom domain.
--   * os / arch   — override the platform tokens used in the artifact
--     filename (default derives from the runtime, e.g. "darwin" / "arm64").
--   * filename    — exact artifact filename, bypassing the default
--     `<tool>_<version>_<os>_<arch>.zip` pattern.
--   * binary_name — the executable's on-disk name (also its in-archive
--     name); defaults to the tool name.
--   * verify      — verify the bytes against the published `.sha256` sidecar
--     (default true; warn and continue when no checksum tool/sidecar is
--     available).
--   * strip       — `archiver.decompress` strip_components guess (default 0
--     for the flat published archives, then falls back to 1 for archives
--     that wrap the binary in a directory).
--
-- @param ctx {tool, version, install_path, download_path, options}
-- @return {} on success; raises on unrecoverable failure.

local archiver = require("archiver")
local cmd = require("cmd")
local file = require("file")
local http = require("http")
local log = require("log")
local strings = require("strings")

-- Production public read base URL for the nidavellir bucket (custom domain
-- nidavellir.mimiskelda.dev on the mimiskelda.dev zone; matches mjolnir's
-- DefaultPublicBaseURL).
local DEFAULT_BASE_URL = "https://nidavellir.mimiskelda.dev"

--- Lowers a runtime platform token to a stable artifact-name token.
local function normalize_os(raw)
    return (raw or ""):lower()
end

--- Extracts `archive` directly into `dest_dir` with the native `archiver`,
-- trying strip_components = `preferred` then the other of {0, 1}, and returns
-- the full path of `binary_name` once it lands directly in `dest_dir`.
--
-- This deliberately avoids shelling out (mkdir/find/mv/chmod): mise runs
-- plugin shell commands with a working directory that does not exist during
-- BackendInstall, so any `sh -c` spawn fails with ENOENT ("os error 2"). The
-- archiver runs natively (no cwd dependency), creates the destination, and
-- preserves the archived file mode — published zips carry the executable bit,
-- so no chmod is needed.
local function extract_binary(archive, dest_dir, binary_name, preferred)
    local dest = file.join_path(dest_dir, binary_name)
    -- Published artifacts are flat (binary at the archive root → strip 0);
    -- try the caller's preference first, then the alternative for archives
    -- that wrap the binary in a single directory.
    local first = preferred or 0
    local second = first == 0 and 1 or 0
    for _, components in ipairs({ first, second }) do
        log.debug(
            "mimiskelda: decompressing",
            archive,
            "into",
            dest_dir,
            "strip_components=" .. tostring(components)
        )
        local ok, derr = pcall(archiver.decompress, archive, dest_dir, { strip_components = components })
        if ok and file.exists(dest) then
            log.debug("mimiskelda: extracted binary to", dest)
            return dest
        end
        log.debug(
            "mimiskelda: strip_components=" .. tostring(components) .. " did not yield " .. dest,
            ok and "" or ("error: " .. tostring(derr))
        )
    end
    error(
        "mimiskelda: extracted "
            .. binary_name
            .. " but no file named '"
            .. binary_name
            .. "' was found at "
            .. dest
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

    -- Artifact filename (explicit override else the established nidavellir
    -- convention `<tool>_<version>_<os>_<arch>.zip`, matching published
    -- terraform-provider-mimiskelda binaries).
    local filename = opts.filename
    if not filename or filename == "" then
        filename = tool .. "_" .. version .. "_" .. os_token .. "_" .. arch_token .. ".zip"
    end

    log.debug(
        "mimiskelda: resolved config",
        "base_url=" .. base_url,
        "os=" .. os_token,
        "arch=" .. arch_token,
        "binary_name=" .. binary_name,
        "filename=" .. filename
    )

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
    log.debug("mimiskelda: verify =", tostring(verify))
    if verify then
        log.debug("mimiskelda: fetching sha256 sidecar", download_url .. ".sha256")
        local sresp, serr = http.try_get({ url = download_url .. ".sha256" })
        local expected = nil
        if serr == nil and sresp.status_code == 200 then
            -- Sidecars may be `<digest>` or `<digest>  <filename>`; keep the hex.
            expected = strings.trim_space(sresp.body or ""):match("%x+")
        else
            log.debug(
                "mimiskelda: sidecar fetch returned",
                serr == nil and tostring(sresp.status_code) or tostring(serr)
            )
        end
        if expected and expected ~= "" then
            log.debug("mimiskelda: expected sha256", expected:lower())
            local ok, out = pcall(cmd.exec, 'shasum -a 256 "' .. archive_path .. '"')
            if not ok then
                log.debug("mimiskelda: shasum failed, trying sha256sum:", tostring(out))
                ok, out = pcall(cmd.exec, 'sha256sum "' .. archive_path .. '"')
            end
            local actual = type(out) == "string" and out:match("%x+") or nil
            if not actual then
                -- No local checksum tool produced a digest; can't verify, but
                -- the download itself succeeded — warn and continue rather
                -- than fail the install.
                log.warn(
                    "mimiskelda: could not compute local sha256 (no usable checksum tool); verification skipped"
                )
            elseif actual:lower() ~= expected:lower() then
                error(
                    "mimiskelda: SHA-256 mismatch for "
                        .. filename
                        .. " (expected "
                        .. expected:lower()
                        .. ", got "
                        .. actual:lower()
                        .. ")"
                )
            else
                log.info("mimiskelda: sha256 verified", actual:lower())
            end
        else
            log.warn("mimiskelda: no sha256 sidecar found; verification skipped")
        end
    end

    -- Extract the binary straight into install_path with the native archiver.
    -- No shell is used here (see extract_binary): mise runs plugin shell
    -- commands with an unavailable working directory during install, and the
    -- archiver both creates install_path and preserves the executable bit.
    local dest = extract_binary(archive_path, install_path, binary_name, opts.strip)

    log.info("mimiskelda: installed", tool, version, "to", dest)
    return {}
end