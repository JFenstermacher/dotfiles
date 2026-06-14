# @dotfiles/envs

Resolve [XDG Base Directory](https://specifications.freedesktop.org/basedir-spec/latest/) variables with sensible defaults.

## Variables

| Export              | Default                | Description                  |
|---------------------|------------------------|------------------------------|
| `XDG_CONFIG_HOME`   | `$HOME/.config`        | User-specific config files   |
| `XDG_CACHE_HOME`    | `$HOME/.cache`         | Non-essential cached data    |
| `XDG_DATA_HOME`     | `$HOME/.local/share`   | User-specific data files     |
| `XDG_STATE_HOME`    | `$HOME/.local/state`   | Persistent state             |
| `XDG_RUNTIME_DIR`   | `/run/user/<uid>`¹     | Runtime sockets / files      |
| `XDG_CONFIG_DIRS`   | `['/etc/xdg']`         | System config search paths   |
| `XDG_DATA_DIRS`     | `['/usr/local/share', '/usr/share']` | System data search paths |

¹ On macOS, falls back to `$TMPDIR`. On unsupported platforms, returns `undefined`.

## Helpers

```ts
import { xdgConfig, xdgCache, xdgData, xdgState } from "@dotfiles/envs";

xdgConfig("nvim")       // => /home/user/.config/nvim
xdgCache("pnpm")        // => /home/user/.cache/pnpm
xdgData("nvim/site")    // => /home/user/.local/share/nvim/site
xdgState("zsh")         // => /home/user/.local/state/zsh
```

## Usage

```ts
import { XDG_CONFIG_HOME, getXdgVars, xdgConfig } from "@dotfiles/envs";

console.log(XDG_CONFIG_HOME);      // /home/user/.config
console.log(xdgConfig("nvim"));    // /home/user/.config/nvim
console.log(getXdgVars());
```
