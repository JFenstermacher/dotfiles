import {
  existsSync,
  readFileSync,
  readdirSync,
  unlinkSync,
  writeFileSync,
} from "node:fs";
import { configPath, configsDir } from "../utils/xdg.js";
import { parseYaml, stringifyYaml } from "./yaml.js";
import { PrivateBoxConfig, PrivateBoxConfigSchema } from "./schema.js";
import { validateName } from "./validation.js";

/**
 * Return a sorted list of all config names (filenames without `.yml`).
 */
export function listConfigs(): string[] {
  const dir = configsDir();
  const entries = readdirSync(dir, { withFileTypes: true });
  const names = entries
    .filter((e) => e.isFile() && e.name.endsWith(".yml"))
    .map((e) => e.name.slice(0, -4));
  names.sort((a, b) => a.localeCompare(b));
  return names;
}

/**
 * Load and validate a config by name.
 *
 * Throws if the file does not exist, if the YAML is invalid, if Zod
 * validation fails, or if the `name` field inside the YAML does not match
 * the filename.
 */
export function loadConfig(name: string): PrivateBoxConfig {
  const path = configPath(name);
  if (!existsSync(path)) {
    throw new Error(`Config "${name}" not found at ${path}`);
  }

  let raw: unknown;
  try {
    const content = readFileSync(path, "utf-8");
    raw = parseYaml(content);
  } catch (err) {
    throw new Error(
      `Failed to parse YAML for config "${name}": ${
        err instanceof Error ? err.message : String(err)
      }`
    );
  }

  let config: PrivateBoxConfig;
  try {
    config = PrivateBoxConfigSchema.parse(raw);
  } catch (err) {
    throw new Error(
      `Validation failed for config "${name}": ${
        err instanceof Error ? err.message : String(err)
      }`
    );
  }

  if (config.name !== name) {
    throw new Error(
      `Config name mismatch: file is named "${name}.yml" but the YAML \`name\` field is "${config.name}"`
    );
  }

  return config;
}

/**
 * Save a config to its canonical path.
 *
 * The config is validated with Zod before writing. Invalid configs are
 * never persisted.
 */
export function saveConfig(config: PrivateBoxConfig): void {
  const validated = PrivateBoxConfigSchema.parse(config);
  const path = configPath(validated.name);
  const yaml = stringifyYaml(validated);
  writeFileSync(path, yaml, "utf-8");
}

/**
 * Delete a config file by name.
 *
 * Throws if the file does not exist.
 */
export function deleteConfig(name: string): void {
  const path = configPath(name);
  if (!existsSync(path)) {
    throw new Error(
      `Cannot delete config "${name}": file not found at ${path}`
    );
  }
  unlinkSync(path);
}

/**
 * Check whether a config file exists.
 */
export function configExists(name: string): boolean {
  return existsSync(configPath(name));
}

/**
 * Validate a config name and load the corresponding config.
 *
 * This is the standard entry point used by all commands to avoid
 * duplicating the name validation + load pattern.
 */
export function resolveConfig(name: string): PrivateBoxConfig {
  const trimmedName = name.trim();

  if (!validateName(trimmedName)) {
    throw new Error(
      `Invalid config name: "${trimmedName}". Names must start with a letter and contain only letters, numbers, underscores, and hyphens.`
    );
  }

  return loadConfig(trimmedName);
}
