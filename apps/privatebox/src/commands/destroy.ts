import { rmSync } from "node:fs";

import { resolveConfig } from "../config/store.js";
import {
  createOrSelectStack,
  destroyStack,
  stackExists,
} from "../pulumi/stack-manager.js";
import { stackDir } from "../utils/xdg.js";
import { prompt } from "../utils/prompt.js";
import { displayCard, displaySuccess } from "../tui/display.js";
import { runPulumiPhase } from "../tui/pulumi-phase.js";


export async function runDestroy(name: string): Promise<void> {
  const config = resolveConfig(name);
  const trimmedName = config.name;

  const hasStack = await stackExists(trimmedName);
  if (!hasStack) {
    console.log(`No Pulumi stack found for "${trimmedName}". Nothing to destroy.`);
    return;
  }

  displayCard("Destroy Summary", [
    { text: `This will destroy ALL cloud resources for: ${trimmedName}` },
    { label: "Region", value: config.aws_region },
    { label: "Profile", value: config.aws_profile },
    { blank: true },
    { text: "Resources that will be destroyed:" },
    { text: "• EC2 Instance" },
    { text: "• Security Group" },
    { text: "• Key Pair" },
    { text: "• KMS Key (scheduled for deletion)" },
    ...(config.use_volume ? [{ text: "• EBS Home Volume" }] : []),
    { blank: true },
    { text: "The local config file will NOT be deleted." },
  ]);

  const confirmation = await prompt(
    `\nType "${trimmedName}" to confirm destruction: `
  );
  if (confirmation !== trimmedName) {
    console.log("Confirmation did not match. Aborted.");
    return;
  }

  console.log("\nDestroying resources...");

  // Create/select stack with a no-op program — the stack state already knows
  // what resources exist from the previous up.
  const noopProgram = async () => {};
  const stack = await createOrSelectStack(
    trimmedName,
    noopProgram,
    config.aws_profile,
    config.aws_region
  );

  await runPulumiPhase(
    "Pulumi Destroy",
    "Destroying resources...",
    (onEvent) => destroyStack(stack, onEvent)
  );

  // Clean up local workspace directory
  try {
    rmSync(stackDir(trimmedName), { recursive: true, force: true });
  } catch {
    // Best-effort cleanup
  }

  displaySuccess(`Stack "${trimmedName}" destroyed successfully.`);
  console.log(`  Config file preserved: ${config.name}.yml`);
}
