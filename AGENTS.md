# Agent Instructions

Always use semantic commit messages.

---

## Project Structure

This is a **pnpm workspaces monorepo** with internal packages only — nothing is published.

```
libs/      Internal shared libraries (envs, git, tmux, logger)
apps/      Applications that consume libs
```

All packages are `private: true` and use `"type": "module"`.

## TypeScript Source Libraries

Internal libs export **raw `.ts` source** — no build step, no `dist/`, no `.d.ts` files.

```json
// libs/<name>/package.json
{
  "type": "module",
  "exports": { ".": "./src/index.ts" }
}
```

```json
// libs/<name>/tsconfig.json
{
  "compilerOptions": {
    "target": "ES2022",
    "module": "ESNext",
    "moduleResolution": "bundler",
    "strict": true,
    "noEmit": true,
    "allowImportingTsExtensions": true,
    "types": ["node"]
  },
  "include": ["src"]
}
```

## Node Type Stripping

Node 26+ runs `.ts` directly. This is **strip-only mode**, not full TS compilation. Rules:

- **No enums** — use `const` objects with derived union types:

  ```ts
  export const LogLevel = {
    TRACE: 0, DEBUG: 1, INFO: 2, WARN: 3, ERROR: 4,
  } as const;

  export type LogLevel = (typeof LogLevel)[keyof typeof LogLevel];
  ```

- **Use `import type`** for anything that's `export type` only:

  ```ts
  import type { Workspace } from "./workspaces.ts";
  ```

- **Always use `.ts` extensions** in relative imports:

  ```ts
  import { load } from "./config.ts";
  ```

## pnpm Configuration

`.npmrc` uses modern defaults:

```ini
strict-peer-dependencies=true
auto-install-peers=true
```

Do **not** use `shamefully-hoist`. Symbolic links and content-addressable storage are pnpm's strengths.

## Error Handling with better-result

All side-effect operations return `Result<T, E>` via `TaggedError`.

```ts
const MyError = TaggedError("MyError")<{
  message: string;
  cause?: unknown;
}>();

export function doThing(): Result<void, InstanceType<typeof MyError>> {
  return Result.try({
    try: () => somethingThatMayThrow(),
    catch: (cause) => new MyError({ message: "failed", cause }),
  });
}
```

For async operations:

```ts
return Result.tryPromise({
  try: async () => { ... },
  catch: (cause) => new MyError({ message: "failed", cause }),
});
```

## Child Process Wrappers

`promisify(execFile)` returns `{ stdout, stderr }` where stdout may be `Buffer | string`. Normalize before wrapping with `Result.tryPromise`:

```ts
async function runGitVoid(args: string[]): Promise<void> {
  await execFileAsync("git", args);
}

async function runGitOutput(args: string[]): Promise<string> {
  const { stdout } = await execFileAsync("git", args);
  return stdout.toString();
}
```

## XDG Base Directories

Use `@dotfiles/envs` for all path resolution. Match the data type to the XDG spec:

| Data Type | XDG Var | Helper |
|-----------|---------|--------|
| Configuration | `XDG_CONFIG_HOME` | `xdgConfig(...)` |
| Application data | `XDG_DATA_HOME` | `xdgData(...)` |
| Session/state | `XDG_STATE_HOME` | `xdgState(...)` |
| Cache/temp | `XDG_CACHE_HOME` | `xdgCache(...)` |

## Logging

Use `@dotfiles/logger` with typed primitive attributes only:

```ts
export type LogAttrValue = string | number | boolean | null;
```

The config shape is:

```ts
type LoggerConfig = {
  consoleEnabled: boolean;
  consoleLevel: LogLevel;
  fileEnabled: boolean;
  fileLevel: LogLevel;
  filePath: string;
};
```

## File Concurrency

State files accessed by multiple processes must use a mutex. Use `proper-lockfile` with a `withLock` helper:

```ts
async function withLock<T>(filePath: string, fn: () => Promise<T>): Promise<T> {
  const release = await lock.lock(filePath, { realpath: false });
  try { return await fn(); } finally { await release(); }
}
```
