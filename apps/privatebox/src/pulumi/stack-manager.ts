import {
  LocalWorkspace,
  Stack,
  InlineProgramArgs,
  EngineEvent,
  PulumiFn,
} from "@pulumi/pulumi/automation";
import type {
  PreviewResult,
  UpResult,
  DestroyResult,
  UpdateSummary,
} from "@pulumi/pulumi/automation";
import { existsSync, readFileSync } from "node:fs";
import { join } from "node:path";
import { stackDir, pulumiBackendDir } from "../utils/xdg.js";

/**
 * Check whether a Pulumi stack already exists for the given config name.
 * Uses the local file backend path directly for a lightweight check.
 */
function stackStatePath(name: string): string {
  return join(
    pulumiBackendDir(),
    ".pulumi",
    "stacks",
    "privatebox",
    `${name}.json`
  );
}

export async function stackExists(name: string): Promise<boolean> {
  return existsSync(stackStatePath(name));
}

/**
 * Read stack outputs directly from the local Pulumi state file.
 * This is intentionally read-only and avoids starting Automation API for list/get/fuzzy flows.
 */
export function readStackOutputs(name: string): Record<string, any> | null {
  const path = stackStatePath(name);
  if (!existsSync(path)) return null;

  const state = JSON.parse(readFileSync(path, "utf-8"));
  const resources =
    state.deployment?.resources ?? state.checkpoint?.latest?.resources;
  const outputs = state.outputs ?? resources?.find(
    (r: any) => r.type === "pulumi:pulumi:Stack"
  )?.outputs;

  if (!outputs || typeof outputs !== "object") return {};

  const result: Record<string, any> = {};
  for (const [key, value] of Object.entries(outputs)) {
    result[key] =
      value && typeof value === "object" && "value" in (value as any)
        ? (value as any).value
        : value;
  }
  return result;
}

// ── Stack creation / selection ──────────────────────────────────────────────

/**
 * Create or select a Pulumi stack for the named private box.
 *
 * Configures the local file backend, workspace directory, and AWS provider
 * settings (`aws-native:region` and `aws-native:profile`).
 */
export async function createOrSelectStack(
  name: string,
  program: PulumiFn,
  awsProfile: string,
  awsRegion: string
): Promise<Stack> {
  const workDir = stackDir(name);
  const backendDir = pulumiBackendDir();

  const args: InlineProgramArgs = {
    stackName: name,
    projectName: "privatebox",
    program,
  };

  const stack = await LocalWorkspace.createOrSelectStack(args, {
    workDir,
    projectSettings: {
      name: "privatebox",
      runtime: {
        name: "nodejs",
        options: {
          nodeargs: "--max-old-space-size=4096",
        },
      } as any,
      backend: {
        url: `file://${backendDir}`,
      },
    },
    // PrivateBox does not currently store Pulumi config secrets. Use a stable,
    // app-local passphrase so non-interactive Automation API stack creation
    // does not require users to export PULUMI_CONFIG_PASSPHRASE themselves.
    envVars: {
      PULUMI_CONFIG_PASSPHRASE:
        process.env.PULUMI_CONFIG_PASSPHRASE ?? "privatebox-local-state",
    },
  });

  // Always update provider config so that profile/region changes are applied
  await stack.setConfig("aws-native:region", { value: awsRegion });
  await stack.setConfig("aws-native:profile", { value: awsProfile });

  return stack;
}

// ── Stack lifecycle operations ──────────────────────────────────────────────

/**
 * Run a Pulumi preview.
 *
 * An optional `onEvent` callback can stream {@link EngineEvent}s to a TUI.
 */
export async function previewStack(
  stack: Stack,
  onEvent?: (event: EngineEvent) => void
): Promise<PreviewResult> {
  return stack.preview({ onEvent });
}

/**
 * Run Pulumi up and return the update summary.
 *
 * An optional `onEvent` callback can stream {@link EngineEvent}s to a TUI.
 */
export async function upStack(
  stack: Stack,
  onEvent?: (event: EngineEvent) => void
): Promise<UpdateSummary> {
  const result: UpResult = await stack.up({ onEvent });
  return result.summary;
}

/**
 * Run Pulumi destroy, remove the stack from the workspace, and return the
 * update summary.
 *
 * An optional `onEvent` callback can stream {@link EngineEvent}s to a TUI.
 */
export async function destroyStack(
  stack: Stack,
  onEvent?: (event: EngineEvent) => void
): Promise<UpdateSummary> {
  const result: DestroyResult = await stack.destroy({ onEvent });
  await stack.workspace.removeStack(stack.name);
  return result.summary;
}

// ── Stack outputs ───────────────────────────────────────────────────────────

/**
 * Return a plain object mapping output keys to their values.
 */
export async function getStackOutputs(
  stack: Stack
): Promise<Record<string, any>> {
  const outputs = await stack.outputs();
  const result: Record<string, any> = {};
  for (const [key, val] of Object.entries(outputs)) {
    result[key] = val.value;
  }
  return result;
}
