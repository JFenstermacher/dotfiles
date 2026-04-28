import { resolveConfig } from "../config/store.js";
import { displaySuccess } from "../tui/display.js";
import {
  describeInstance,
  getStackInstanceId,
  transitionInstance,
} from "../utils/instance.js";

export async function runUp(name: string): Promise<void> {
  const config = resolveConfig(name);
  const trimmedName = config.name;
  const instanceId = await getStackInstanceId(trimmedName);
  const current = await describeInstance(config, instanceId);

  if (current.state === "running") {
    console.log(`Instance "${trimmedName}" is already running.`);
    console.log(`  Instance ID: ${instanceId}`);
    if (current.publicIp) console.log(`  Public IP:   ${current.publicIp}`);
    if (current.privateIp) console.log(`  Private IP:  ${current.privateIp}`);
    return;
  }

  if (current.state === "terminated" || current.state === "shutting-down") {
    throw new Error(`Instance ${instanceId} is ${current.state}. Cannot start it.`);
  }

  console.log(`Starting instance ${instanceId}...`);
  console.log(`Waiting for instance to reach running state...`);
  const final = await transitionInstance({
    config,
    instanceId,
    targetState: "running",
  });

  displaySuccess(`Instance "${trimmedName}" is now running.`);
  console.log(`  Instance ID: ${instanceId}`);
  if (final.publicIp) console.log(`  Public IP:   ${final.publicIp}`);
  if (final.privateIp) console.log(`  Private IP:  ${final.privateIp}`);
}
