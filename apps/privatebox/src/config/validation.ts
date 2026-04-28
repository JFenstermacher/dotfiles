import { ZodError } from "zod";
import {
  CONFIG_NAME_REGEX,
  PrivateBoxConfig,
  PrivateBoxConfigSchema,
} from "./schema.js";

/**
 * Validate an unknown value as a complete PrivateBoxConfig.
 *
 * Throws a ZodError if validation fails.
 */
export function validateConfig(data: unknown): PrivateBoxConfig {
  return PrivateBoxConfigSchema.parse(data);
}

/**
 * Check whether a string is a valid config identifier.
 */
export function validateName(name: string): boolean {
  return CONFIG_NAME_REGEX.test(name);
}

/**
 * Format a ZodError into human-readable lines suitable for CLI/TUI display.
 */
export function formatValidationErrors(error: ZodError): string {
  const lines = error.issues.map((issue) => {
    const path = issue.path.length > 0 ? issue.path.join(".") : "<root>";
    return `  • ${path}: ${issue.message}`;
  });
  return lines.join("\n");
}
