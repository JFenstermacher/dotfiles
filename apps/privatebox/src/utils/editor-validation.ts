import { unlinkSync } from "node:fs";
import { ZodError } from "zod";
import { PrivateBoxConfig } from "../config/schema.js";
import { validateConfig, formatValidationErrors } from "../config/validation.js";
import { parseYaml } from "../config/yaml.js";
import { openEditorWithContent } from "./editor.js";
import { prompt } from "./prompt.js";



function cleanupDraft(path: string): void {
  try {
    unlinkSync(path);
  } catch {
    // Best-effort cleanup
  }
}

// ── Shared editor validation loop ───────────────────────────────────────────

export interface EditorValidationOptions {
  /** If provided, this name is injected into the parsed object before validation,
   *  overriding any `name` field the user may have edited. */
  injectName?: string;
}

/**
 * Open an editor with initial YAML content and repeatedly validate the result
 * until the user either produces a valid config or aborts.
 *
 * On retry, the editor re-opens with the current (possibly invalid) YAML so
 * the user can fix their mistake without retyping everything.
 *
 * Returns the validated config, or `null` if the user aborted.
 */
export async function runEditorValidationLoop(
  initialYaml: string,
  draftPath: string,
  options?: EditorValidationOptions
): Promise<PrivateBoxConfig | null> {
  let currentYaml = initialYaml;

  while (true) {
    const editedYaml = openEditorWithContent(currentYaml, draftPath);
    currentYaml = editedYaml;

    let parsed: Record<string, unknown>;
    try {
      parsed = parseYaml(editedYaml) as Record<string, unknown>;
    } catch (err) {
      console.error(
        `\nYAML parse error: ${err instanceof Error ? err.message : String(err)}`
      );
      const action = await prompt("  [r]etry / [a]bort? ");
      if (action.toLowerCase() === "a") {
        cleanupDraft(draftPath);
        return null;
      }
      continue;
    }

    if (options?.injectName) {
      parsed.name = options.injectName;
    }

    try {
      const config = validateConfig(parsed);
      cleanupDraft(draftPath);
      return config;
    } catch (err) {
      if (err instanceof ZodError) {
        console.error(`\nValidation failed:\n${formatValidationErrors(err)}`);
      } else {
        console.error(
          `\nValidation failed: ${err instanceof Error ? err.message : String(err)}`
        );
      }
      const action = await prompt("  [r]etry / [a]bort? ");
      if (action.toLowerCase() === "a") {
        cleanupDraft(draftPath);
        return null;
      }
      // Retry: re-open editor with current (invalid) YAML
    }
  }
}
