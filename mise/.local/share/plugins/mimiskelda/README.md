# mimiskelda — nidavellir binary release backend for mise

A [mise](https://mise.jdx.dev) **backend plugin** that installs binary
releases published to the [nidavellir](https://github.com/mimiskelda/yggdrasil/tree/main/apps/nidavellir)
artifact store. Tools are referenced as `mimiskelda:<tool>` (e.g.
`mimiskelda:sessionizer`).

This backend is **binary-install only** — every tool is a prebuilt per-OS,
per-arch executable. It does not build anything.

## How it works

nidavellir stores each artifact at a public, keyless R2 read URL under the
deterministic key:

```
<base_url>/artifacts/<tool>/<version>/<filename>
```

A `<filename>.sha256` sidecar beside each artifact publishes its digest.

- `BackendListVersions` resolves available versions from the owning
  repository's GitHub releases (each tool is a component tag
  `<tool>-v<version>`, e.g. `sessionizer-v1.0.0`).
- `BackendInstall` downloads the artifact for the current OS/arch (default
  `<tool>_<version>_<os>_<arch>.zip`), verifies its published SHA-256
  sidecar, extracts it, and places the executable into the installation
  root.
- `BackendExecEnv` prepends the installation root to `PATH`.

## Usage

Add the plugin (this repo links it into `~/.local/share/mise/plugins/mimiskelda`):

```bash
mise dotfiles apply            # or: mise bootstrap dotfiles apply
```

Declare a tool:

```toml
[tools]
"mimiskelda:sessionizer" = { version = "latest" }
```

Install and run:

```bash
mise install mimiskelda:sessionizer
mise use   mimiskelda:sessionizer
mise exec  -- sessionizer --version
```

## Configuration (`mimiskelda:<tool>` table)

| Option | Type | Default | Purpose |
|---|---|---|---|
| `base_url` | string | `MIMISKELDA_PUBLIC_BASE_URL` env, else the production nidavellir custom domain `nidavellir.mimiskelda.dev` | nidavellir public read base URL (no trailing slash) |
| `os` / `arch` | string | derived from the runtime (`darwin`, `arm64`, …) | platform tokens used in the default artifact filename |
| `filename` | string | `<tool>_<version>_<os>_<arch>.zip` | exact artifact filename on nidavellir |
| `binary_name` | string | `<tool>` | the executable's on-disk (and in-archive) name |
| `verify` | bool | `true` | verify bytes against the published `<filename>.sha256` sidecar |
| `strip` | number | `1` | `archiver.decompress` strip_components guess |

`base_url` can also be set process-wide with `MIMISKELDA_PUBLIC_BASE_URL`.

## Hooks

- `hooks/backend_list_versions.lua` — `BackendListVersions`
- `hooks/backend_install.lua` — `BackendInstall`
- `hooks/backend_exec_env.lua` — `BackendExecEnv`