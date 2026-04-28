import { spawnSync } from "node:child_process";
import { readFileSync, writeFileSync, unlinkSync } from "node:fs";
import { join } from "node:path";
import { cacheDir } from "./xdg.js";

// ── Editor resolution ───────────────────────────────────────────────────────

function getEditorCommand(): string {
  const editor = process.env.EDITOR;
  return editor && editor.trim().length > 0 ? editor.trim() : "vi";
}

// ── Core editor runner ──────────────────────────────────────────────────────

function runEditor(filePath: string): void {
  const editor = getEditorCommand();

  const result = spawnSync(editor, [filePath], {
    stdio: "inherit",
    shell: true,
  });

  if (result.error) {
    throw new Error(
      `Failed to open editor "${editor}": ${result.error.message}`
    );
  }

  if (result.signal) {
    throw new Error(
      `Editor "${editor}" was terminated by signal ${result.signal}`
    );
  }

  if (result.status !== 0 && result.status !== null) {
    throw new Error(`Editor "${editor}" exited with code ${result.status}`);
  }
}

// ── Public API ──────────────────────────────────────────────────────────────

/**
 * Write initial YAML content to a file (or a temp file), open it in the
 * user's preferred editor, and return the edited content.
 *
 * When `filePath` is omitted, a temporary file under the PrivateBox cache
 * directory is created and cleaned up automatically.
 */
export function openEditorWithContent(
  initialYaml: string,
  filePath?: string
): string {
  const isTemp = filePath === undefined;
  const targetPath =
    filePath ?? join(cacheDir(), `privatebox-edit-${Date.now()}.yml`);

  writeFileSync(targetPath, initialYaml, { encoding: "utf-8" });

  try {
    runEditor(targetPath);
    return readFileSync(targetPath, { encoding: "utf-8" });
  } finally {
    if (isTemp) {
      try {
        unlinkSync(targetPath);
      } catch {
        // Best-effort cleanup of temp file
      }
    }
  }
}
