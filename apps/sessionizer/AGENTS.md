# Sessionizer Agent Learnings

## Node Type Stripping

Node 26+ can run `.ts` directly but the **strip-only mode has strict limits**:

- **Enums are not supported** — must use `const` objects with derived union types:

  ```ts
  export const LogLevel = {
    TRACE: 0,
    DEBUG: 1,
  } as const;

  export type LogLevel = (typeof LogLevel)[keyof typeof LogLevel];
  ```

- **`import type` is required** when importing a type that's only `export type`:

  ```ts
  // ❌ SyntaxError at runtime — Node expects a value export
  import { Workspace } from "./workspaces.ts";

  // ✓ Correct
  import type { Workspace } from "./workspaces.ts";
  ```

## tsconfig for .ts Extension Imports

When importing with `.ts` extensions (required for Node type stripping), enable:

```json
{ "compilerOptions": { "allowImportingTsExtensions": true } }
```

## Monorepo Library Pattern

Internal libs don't need a compile step. Point consumers directly at `.ts` source:

```json
{ "exports": { ".": "./src/index.ts" } }
```

Use `noEmit: true` in `tsconfig.json` — no `dist/`, no `.d.ts` files.

## pnpm Best Practices

```ini
strict-peer-dependencies=true
auto-install-peers=true
```

Avoid `shamefully-hoist` for new projects.

## better-result Patterns

- Use `Result.try` / `Result.tryPromise` to wrap operations that may throw.
- For typed errors, create `TaggedError` factories, then instantiate with `new ErrorConstructor({ message, cause })`.
- `Result.err()` must be passed an error instance; passing a raw string or object loses narrowing.

```ts
const MyError = TaggedError("MyError")<{ message: string }>();
return Result.err(new MyError({ message: "oops" }));
```

## Child Process with better-result

`promisify(execFile)` returns `{ stdout, stderr }` where stdout may be `Buffer | string`. Normalize with a wrapper before passing to `Result.tryPromise`.
