-- hooks/backend_list_versions.lua
-- BackendListVersions: lists the released versions of `tool` from nidavellir.
--
-- nidavellir has no "list API" endpoint (downloads are direct, keyless reads
-- off R2). Versions are instead resolved from the owning repository's GitHub
-- releases, where each tool is a component with a release tag of the shape
-- `<tool>-v<version>` (e.g. `sessionizer-v1.0.0`). This hook queries the
-- GitHub releases API and returns the versions whose tag carries the
-- `-v<version>` prefix for the requested tool.
--
-- Repo override via ctx.options.repo (default `mimiskelda/yggdrasil`).
--
-- @param ctx {tool: string, options: table} Context
-- @return {versions = {string, ...}} Available versions, ascending

local json = require("json")
local http = require("http")
local log = require("log")
local semver = require("semver")

-- Default repository hosting the tool components' release tags.
local DEFAULT_REPO = "mimiskelda/yggdrasil"

--- Fetches one page of the GitHub releases listing (per_page=100).
-- Returns the decoded release array, or raises on transport/HTTP error.
local function fetch_releases(repo)
    local url = "https://api.github.com/repos/" .. repo .. "/releases?per_page=100"
    log.debug("mimiskelda: fetching releases from", url)
    local resp, err = http.try_get({
        url = url,
        headers = { ["User-Agent"] = "mise-mimiskelda-plugin" },
    })
    if err ~= nil then
        error("mimiskelda: failed to fetch releases for " .. repo .. ": " .. tostring(err))
    end
    if resp.status_code ~= 200 then
        error(
            "mimiskelda: GitHub releases API returned "
                .. tostring(resp.status_code)
                .. ": "
                .. tostring(resp.body)
        )
    end
    local ok, releases = pcall(json.decode, resp.body)
    if not ok then
        error("mimiskelda: failed to parse releases JSON: " .. tostring(releases))
    end
    log.debug("mimiskelda: fetched", tostring(#releases), "releases from", repo)
    return releases
end

function PLUGIN:BackendListVersions(ctx)
    local tool = ctx.tool
    if not tool or tool == "" then
        error("mimiskelda: tool name cannot be empty")
    end

    local repo = DEFAULT_REPO
    if ctx.options ~= nil and ctx.options.repo ~= nil then
        repo = ctx.options.repo
    end

    local releases = fetch_releases(repo)

    -- Tag shape is `<tool>-v<version>` (release-please component tag). Strip
    -- the prefix and keep the semver part, ignoring any other release tags.
    local prefix = tool .. "-v"
    local versions = {}
    for _, rel in ipairs(releases) do
        local tag = rel.tag_name or rel.name or ""
        if tag:sub(1, #prefix) == prefix then
            local ver = tag:sub(#prefix + 1)
            -- Trim surrounding whitespace with standard Lua string ops.
            ver = (ver:gsub("^%s+", "")):gsub("%s+$", "")
            if ver ~= "" then
                table.insert(versions, ver)
            end
        end
    end

    -- Semantically ascending (mise expects oldest → newest and picks the
    -- highest for `latest`).
    table.sort(versions, function(a, b)
        return semver.compare(a, b) < 0
    end)

    if #versions == 0 then
        error("mimiskelda: no releases found for tool '" .. tool .. "' in " .. repo)
    end

    log.debug(
        "mimiskelda: matched",
        tostring(#versions),
        "versions for",
        tool,
        "(latest " .. versions[#versions] .. ")"
    )
    return { versions = versions }
end