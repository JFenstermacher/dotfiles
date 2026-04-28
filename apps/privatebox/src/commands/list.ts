import { listConfigs, loadConfig, resolveConfig } from "../config/store.js";
import { readStackOutputs, stackExists } from "../pulumi/stack-manager.js";
import { displayTable } from "../tui/display.js";
import { describeInstance } from "../utils/instance.js";

export async function runListConfigs(): Promise<void> {
  const names = listConfigs();
  if (names.length === 0) {
    console.log("No configs found. Run `privatebox configure <name>` to create one.");
    return;
  }

  const rows: string[][] = [];
  for (const name of names) {
    try {
      const cfg = loadConfig(name);
      const vol = cfg.use_volume ? `${cfg.volume_size}G` : "off";
      rows.push([
        name,
        cfg.aws_region,
        cfg.ami,
        cfg.instance_type,
        "on",
        vol,
        cfg.enable_public_ip ? "yes" : "no",
        cfg.aws_profile,
      ]);
    } catch {
      rows.push([name, "(invalid)", "", "", "", "", "", ""]);
    }
  }

  displayTable(
    ["Name", "Region", "AMI", "Type", "KMS", "Vol", "Public IP", "Profile"],
    rows
  );
}

export async function runListInstances(): Promise<void> {
  const names = listConfigs();
  const rows: string[][] = [];

  for (const name of names) {
    if (!(await stackExists(name))) continue;

    try {
      const cfg = resolveConfig(name);
      const outputs = readStackOutputs(name) ?? {};
      const instanceId = outputs.instanceId as string | undefined;

      let status = "unknown";
      let publicIp = outputs.publicIp as string | undefined;
      let privateIp = outputs.privateIp as string | undefined;

      if (instanceId) {
        const info = await describeInstance(cfg, instanceId);
        status = info.state;
        publicIp = info.publicIp ?? publicIp;
        privateIp = info.privateIp ?? privateIp;
      }

      rows.push([
        name,
        status,
        publicIp ?? "n/a",
        privateIp ?? "n/a",
        cfg.instance_type,
        cfg.aws_region,
        cfg.aws_profile,
      ]);
    } catch {
      // skip configs with broken stacks
    }
  }

  if (rows.length === 0) {
    console.log("No active instances found. Run `privatebox apply <name>` to create one.");
    return;
  }

  displayTable(
    ["Name", "Status", "Public IP", "Private IP", "Type", "Region", "Profile"],
    rows
  );
}
