import { readFileSync, existsSync, statSync } from "node:fs";
import { loadConfig, resolveConfig } from "../config/store.js";
import { configPath } from "../utils/xdg.js";
import { readStackOutputs, stackExists } from "../pulumi/stack-manager.js";
import { describeInstance } from "../utils/instance.js";
import { fileUrlPath } from "../utils/path.js";
import { displayCard } from "../tui/display.js";

export async function runGetConfig(name: string): Promise<void> {
  const config = resolveConfig(name);
  const trimmedName = config.name;

  const path = configPath(trimmedName);
  if (!existsSync(path)) {
    throw new Error(`Config "${trimmedName}" not found at ${path}`);
  }

  const content = readFileSync(path, "utf-8");
  const stats = statSync(path);

  console.log(`\nConfig: ${trimmedName}`);
  console.log(`Path:   ${path}`);
  console.log(`Modified: ${stats.mtime.toISOString()}`);
  console.log("\n--- YAML ---\n");
  console.log(content);

  const cfg = loadConfig(trimmedName);
  if (cfg.public_key.startsWith("file://")) {
    const keyPath = fileUrlPath(cfg.public_key);
    console.log(`\nSSH public key file: ${keyPath} ${existsSync(keyPath) ? "(exists)" : "(NOT FOUND)"}`);
  }
}

export async function runGetInstance(name: string): Promise<void> {
  const config = resolveConfig(name);
  const trimmedName = config.name;

  if (!(await stackExists(trimmedName))) {
    throw new Error(
      `No stack found for "${trimmedName}". Run "privatebox apply ${trimmedName}" first.`
    );
  }

  const outputs = readStackOutputs(trimmedName) ?? {};
  const instanceId = outputs.instanceId as string | undefined;

  let liveStatus = "unknown";
  let launchTime: string | undefined;
  let publicIp = outputs.publicIp as string | undefined;
  let privateIp = outputs.privateIp as string | undefined;

  if (instanceId) {
    const info = await describeInstance(config, instanceId);
    liveStatus = info.state;
    launchTime = info.launchTime;
    publicIp = info.publicIp ?? publicIp;
    privateIp = info.privateIp ?? privateIp;
  }

  displayCard(
    "Instance Details",
    [
      { label: "Name", value: trimmedName },
      { label: "Region", value: config.aws_region },
      { label: "Status", value: liveStatus },
      { label: "Instance ID", value: instanceId ?? "n/a" },
      { label: "AMI", value: config.ami },
      { label: "Instance Type", value: config.instance_type },
      ...(launchTime ? [{ label: "Launch Time", value: launchTime }] : []),
      { label: "Public IP", value: publicIp ?? "n/a" },
      { label: "Private IP", value: privateIp ?? "n/a" },
      { label: "VPC", value: (outputs.vpcId as string) ?? "n/a" },
      { label: "Subnet", value: (outputs.subnetId as string) ?? "n/a" },
      { label: "AZ", value: (outputs.availabilityZone as string) ?? "n/a" },
      { label: "Security Group", value: (outputs.securityGroupId as string) ?? "n/a" },
      { label: "Key Pair", value: (outputs.keyPairName as string) ?? "n/a" },
      { label: "KMS Key ID", value: (outputs.kmsKeyId as string) ?? "n/a" },
      { label: "KMS Key ARN", value: (outputs.kmsKeyArn as string) ?? "n/a" },
      ...(outputs.volumeId
        ? [
            { label: "Volume ID", value: (outputs.volumeId as string) ?? "n/a" },
            {
              label: "Volume Size",
              value: config.use_volume ? `${config.volume_size} GiB` : "n/a",
            },
          ]
        : []),
      { label: "Username", value: config.username },
      { label: "Public IP", value: String(config.enable_public_ip) },
      ...(outputs.privateKeyPath
        ? [{ label: "SSH Key Path", value: outputs.privateKeyPath as string }]
        : []),
    ],
    120
  );
}
