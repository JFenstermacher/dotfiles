-- metadata.lua
-- Backend plugin metadata and configuration.
--
-- This backend installs binaries published to the shipyard artifact store
-- (~/workspaces/mimiskelda/yggdrasil/apps/shipyard). It is a "binary install
-- only" backend: every tool is installed by downloading a per-platform,
-- per-architecture binary archive from shipyard's public R2 read URL,
-- verifying its published SHA-256 sidecar, extracting it, and exposing the
-- contained executable on PATH.
--
-- Docs: https://mise.jdx.dev/backend-plugin-development.html

PLUGIN = { -- luacheck: ignore
    -- Required: Plugin name (the backend prefix users reference: `mimiskelda:sessionizer`).
    name = "mimiskelda",

    -- Required: Plugin version (NOT the tool versions).
    version = "1.0.0",

    -- Required: Brief description.
    description = "Installs binary releases published to the shipyard artifact store (mimiskelda/yggdrasil)",

    -- Required: Plugin author/maintainer.
    author = "mimiskelda",

    -- Optional: Plugin homepage/repository URL.
    homepage = "https://github.com/mimiskelda/yggdrasil",

    -- Optional: Plugin license.
    license = "MIT",
}