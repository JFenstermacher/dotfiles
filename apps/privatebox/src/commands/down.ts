import { resolveConfig } from "../config/store.js";
import { displaySuccess } from "../tui/display.js";
import {
  describeInstance,
  getStackInstanceId,
  transitionInstance,
} from "../utils/instance.js";

export async function runDown(name: string): Promise<void> {
  const config = resolveConfig(name);
  const trimmedName = config.name;
  const instanceId = await getStackInstanceId(trimmedName);
  const current = await describeInstance(config, instanceId);

  if (current.state === "stopped") {
    console.log(`Instance "${trimmedName}" is already stopped.`);
    console.log(`  Instance ID: ${instanceId}`);
    return;
  }

  if (current.state === "terminated" || current.state === "shutting-down") {
    throw new Error(`Instance ${instanceId} is ${current.state}. Cannot stop it.`);
  }

  console.log(`Stopping instance ${instanceId}...`);
  console.log(`Waiting for instance to reach stopped state...`);
  await transitionInstance({
    config,
    instanceId,
    targetState: "stopped",
  });

  displaySuccess(`Instance "${trimmedName}" is now stopped.`);
  console.log(`  Instance ID: ${instanceId}`);
  console.log(`  Encrypted EBS volumes, KMS keys, and other resources are preserved.`);
  console.log(`  Note: preserved resources may still incur AWS costs.`);
}
