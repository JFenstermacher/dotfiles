import { join } from "node:path";
import {
  configExists,
  resolveConfig,
  saveConfig,
  deleteConfig,
} from "../config/store.js";
import { validateName } from "../config/validation.js";
import { runEditorValidationLoop } from "../utils/editor-validation.js";
import { cacheDir, configPath } from "../utils/xdg.js";
import { stringifyYaml } from "../config/yaml.js";
import { stackExists } from "../pulumi/stack-manager.js";
import { prompt } from "../utils/prompt.js";


// ── Main command ────────────────────────────────────────────────────────────

export async function runEdit(originalName: string): Promise<void> {
  const trimmedName = originalName.trim();

  if (!validateName(trimmedName)) {
    throw new Error(
      `Invalid config name: "${trimmedName}". Names must start with a letter and contain only letters, numbers, underscores, and hyphens.`
    );
  }

  if (!configExists(trimmedName)) {
    throw new Error(
      `Config "${trimmedName}" not found. Run \`privatebox configure ${trimmedName}\` to create it.`
    );
  }

  const existingConfig = resolveConfig(trimmedName);
  const initialYaml = stringifyYaml(existingConfig);

  const draftPath = join(cacheDir(), `edit-draft-${trimmedName}.yml`);

  console.log(`Editing config "${trimmedName}"...`);

  const config = await runEditorValidationLoop(initialYaml, draftPath);
  if (!config) {
    console.log("Aborted. No changes were saved.");
    return;
  }

  // ── Handle name change ───────────────────────────────────────────────────
  if (config.name !== trimmedName) {
    if (await stackExists(trimmedName)) {
      throw new Error(
        `Cannot rename config "${trimmedName}" to "${config.name}": a Pulumi stack exists for "${trimmedName}". ` +
        `Run \`privatebox destroy ${trimmedName}\` first, then edit and rename.`
      );
    }

    if (!validateName(config.name)) {
      throw new Error(
        `Invalid new config name: "${config.name}". Names must start with a letter and contain only letters, numbers, underscores, and hyphens.`
      );
    }

    if (configExists(config.name)) {
      throw new Error(
        `Cannot rename config "${trimmedName}" to "${config.name}": a config with that name already exists.`
      );
    }

    const confirmMsg =
      `You changed the config name from "${trimmedName}" to "${config.name}". ` +
      `This will save a new config file and delete the old one. Continue? [y/N] `;
    const confirmed = await prompt(confirmMsg);
    if (confirmed.toLowerCase() !== "y") {
      console.log("Aborted. No changes were saved.");
      return;
    }

    saveConfig(config);
    deleteConfig(trimmedName);
    console.log(`Config renamed and saved: ${configPath(config.name)}`);
    console.log(`Old config deleted: ${configPath(trimmedName)}`);
    return;
  }

  // ── Same name ────────────────────────────────────────────────────────────
  saveConfig(config);
  console.log(`Config saved: ${configPath(config.name)}`);
}
