import { mkdir, readFile, writeFile, rm, access } from "node:fs/promises";
import { dirname } from "node:path";
import { spawn } from "node:child_process";
import { Result, TaggedError } from "better-result";
import { z } from "zod";
import { xdgConfig } from "@dotfiles/envs";
import { LogLevel } from "@dotfiles/logger";

const ConfigHomeError = TaggedError("ConfigHomeError")<{
  message: string;
  cause: unknown;
}>();

const SaveError = TaggedError("SaveError")<{
  message: string;
  cause: unknown;
}>();

const LoadError = TaggedError("LoadError")<{
  message: string;
  cause: unknown;
}>();

const EditError = TaggedError("EditError")<{
  message: string;
  cause?: unknown;
}>();

const logLevelSchema = z.enum([
  LogLevel.TRACE,
  LogLevel.DEBUG,
  LogLevel.INFO,
  LogLevel.WARN,
  LogLevel.ERROR,
]);

export const ConfigSchema = z.object({
  githubOwners: z.array(z.string()),
  consoleEnabled: z.boolean(),
  consoleLevel: logLevelSchema,
  fileEnabled: z.boolean(),
  fileLevel: logLevelSchema,
  filePath: z.string(),
  databaseDir: z.string(),
});

export type Config = z.infer<typeof ConfigSchema>;

export const DEFAULT_CONFIG: Config = {
  githubOwners: ["JFenstermacher"],
  consoleEnabled: true,
  consoleLevel: LogLevel.INFO,
  fileEnabled: true,
  fileLevel: LogLevel.DEBUG,
  filePath: `${process.env.HOME}/.local/share/sessionizer/sessionizer.jsonl`,
  databaseDir: `${process.env.HOME}/.local/share/sessionizer`,
};

/**
 * Resolve the path to the sessionizer config file inside `$XDG_CONFIG_HOME`.
 *
 * @returns `Ok` with the absolute config file path, or `Err(ConfigHomeError)`
 *          if `$HOME` is missing and the path cannot be resolved.
 */
export function configHome(): Result<
  string,
  InstanceType<typeof ConfigHomeError>
> {
  return Result.try({
    try: () => xdgConfig("sessionizer", "config.json"),
    catch: (cause) =>
      new ConfigHomeError({
        message: "Failed to resolve config home",
        cause,
      }),
  });
}

/**
 * Persist the given configuration as JSON to the sessionizer config file.
 *
 * @param config – The configuration object to save.
 * @returns `Ok(void)` on success, or `Err(SaveError)` on failure.
 */
export function save(
  config: Config,
): Promise<Result<void, InstanceType<typeof SaveError>>> {
  return Result.tryPromise({
    try: async () => {
      const path = xdgConfig("sessionizer", "config.json");
      await mkdir(dirname(path), { recursive: true });
      await writeFile(path, JSON.stringify(config, null, 2));
    },
    catch: (cause) =>
      new SaveError({
        message: "Failed to save config",
        cause,
      }),
  });
}

function validateConfig(
  value: unknown,
): Result<Config, InstanceType<typeof EditError>> {
  const parsed = ConfigSchema.safeParse(value);
  if (!parsed.success) {
    const issues = parsed.error.issues.map((i) => `${i.path.join(".")}: ${i.message}`);
    return Result.err(
      new EditError({
        message: `Config validation failed: ${issues.join("; ")}`,
        cause: parsed.error,
      }),
    );
  }
  return Result.ok(parsed.data);
}

/**
 * Open the sessionizer config file in `$EDITOR`.
 *
 * Creates a temp copy of the current config, opens it in the editor, validates
 * the edited JSON against the Zod schema, and atomically swaps it to the real
 * config path on success.
 *
 * @returns `Ok(void)` on success, or `Err(EditError)` on failure.
 */
export async function edit(): Promise<Result<
  void,
  InstanceType<typeof EditError>
>> {
  const editor = process.env.EDITOR;
  if (!editor) {
    return Result.err(
      new EditError({ message: "EDITOR environment variable is not set" }),
    );
  }

  const home = configHome();
  if (Result.isError(home)) {
    return Result.err(
      new EditError({
        message: `Failed to resolve config path: ${home.error.message}`,
        cause: home.error,
      }),
    );
  }

  const filePath = home.value;
  const dir = dirname(filePath);
  const tempPath = `${dir}/sessionizer.config.edit.tmp`;

  return Result.tryPromise({
    try: async () => {
      await mkdir(dir, { recursive: true });

      // Seed temp file with current config or defaults
      let seed: Config;
      try {
        const raw = await readFile(filePath, "utf-8");
        seed = JSON.parse(raw) as Config;
      } catch {
        seed = DEFAULT_CONFIG;
      }
      await writeFile(tempPath, JSON.stringify(seed, null, 2));

      // Open editor on temp file
      await new Promise<void>((resolve, reject) => {
        const child = spawn(editor, [tempPath], {
          stdio: "inherit",
          detached: false,
        });
        child.on("error", (err) => reject(err));
        child.on("close", (code) => {
          if (code !== 0 && code !== null) {
            reject(new Error(`Editor exited with code ${code}`));
          } else {
            resolve();
          }
        });
      });

      // Read back and validate
      const editedRaw = await readFile(tempPath, "utf-8");
      const parsed = JSON.parse(editedRaw);
      const validation = validateConfig(parsed);
      if (Result.isError(validation)) {
        throw new EditError({ message: validation.error.message });
      }

      // Write validated content to real path and clean up temp
      await writeFile(filePath, JSON.stringify(validation.value, null, 2));
      await rm(tempPath).catch(() => {});

      return undefined;
    },
    catch: (cause) => {
      if (cause instanceof EditError) {
        return cause;
      }
      return new EditError({
        message: "Failed to open config in editor",
        cause,
      });
    },
  });
}

/**
 * Load the sessionizer configuration from disk.
 *
 * Falls back to `DEFAULT_CONFIG` when the file does not exist, cannot be
 * read, or contains invalid JSON.
 *
 * @returns The loaded configuration, or `DEFAULT_CONFIG` on any failure.
 */
export async function load(): Promise<Config> {
  const result = await Result.tryPromise({
    try: async () => {
      const path = xdgConfig("sessionizer", "config.json");
      const raw = await readFile(path, "utf-8");
      const parsed = JSON.parse(raw);
      const validated = ConfigSchema.safeParse(parsed);
      if (!validated.success) {
        throw new Error(
          `Validation failed: ${validated.error.issues.map((i) => `${i.path.join(".")}: ${i.message}`).join("; ")}`,
        );
      }
      return validated.data;
    },
    catch: (cause) =>
      new LoadError({
        message: "Failed to load config",
        cause,
      }),
  });

  if (Result.isOk(result)) {
    return { ...DEFAULT_CONFIG, ...result.value };
  }
  return DEFAULT_CONFIG;
}
