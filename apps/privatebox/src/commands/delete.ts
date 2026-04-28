import { deleteConfig, resolveConfig } from "../config/store.js";
import { stackExists } from "../pulumi/stack-manager.js";
import { promptYesNo } from "../utils/prompt.js";
import { displaySuccess } from "../tui/display.js";

export async function runDelete(name: string): Promise<void> {
  const config = resolveConfig(name);
  const trimmedName = config.name;

  if (await stackExists(trimmedName)) {
    throw new Error(
      `Cannot delete config while cloud resources exist. Run "privatebox destroy ${trimmedName}" first.`
    );
  }

  const confirmed = await promptYesNo(
    `Delete config "${trimmedName}"? This cannot be undone.`
  );
  if (!confirmed) {
    console.log("Aborted.");
    return;
  }

  deleteConfig(trimmedName);
  displaySuccess(`Config "${trimmedName}" deleted.`);
}
