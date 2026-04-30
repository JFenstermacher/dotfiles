import { existsSync, appendFileSync, mkdirSync, readFileSync } from "node:fs";
import { prompt, promptYesNo } from "../utils/prompt.js";
import { join } from "node:path";
import { homedir } from "node:os";

import { resolveConfig } from "../config/store.js";
import { resolveKmsPolicy } from "../config/kms-policy.js";
import {
  getCallerIdentity,
  normalizePrincipalArn,
  resolveAwsRegion,
} from "../utils/aws.js";
import { resolveNetwork, resolveAmiRootDevice } from "../utils/network.js";
import { resolvePublicKey } from "../pulumi/ssh-keys.js";
import { generateBootstrapScript } from "../pulumi/bootstrap.js";
import { createProgram, ResolvedPrivateBoxConfig } from "../pulumi/program.js";
import {
  createOrSelectStack,
  previewStack,
  upStack,
  getStackOutputs,
} from "../pulumi/stack-manager.js";
import { displayCard } from "../tui/display.js";
import { runPulumiPhase } from "../tui/pulumi-phase.js";
import { expandHome, fileUrlPath, readFileUrl } from "../utils/path.js";

function appendSshConfig(
  name: string,
  host: string,
  user: string,
  identityFile: string
): void {
  const sshDir = join(homedir(), ".ssh");
  mkdirSync(sshDir, { recursive: true });
  const sshConfigPath = join(sshDir, "config");

  const entry = `
# privatebox: ${name}
Host pb-${name}
    HostName ${host}
    User ${user}
    IdentityFile ${identityFile}
    StrictHostKeyChecking accept-new
`;

  if (existsSync(sshConfigPath)) {
    const existing = readFileSync(sshConfigPath, "utf-8");
    if (existing.includes(`# privatebox: ${name}`)) {
      console.log(`  SSH config entry for pb-${name} already exists. Skipping.`);
      return;
    }
  }

  appendFileSync(sshConfigPath, entry, "utf-8");
}

function printApplySummary(
  config: ResolvedPrivateBoxConfig,
  network: { vpcId: string; subnetId: string; availabilityZone: string }
): void {
  displayCard("Apply Summary", [
    { label: "Name", value: config.name },
    { label: "Region", value: config.aws_region },
    { label: "VPC", value: network.vpcId },
    { label: "Subnet", value: network.subnetId },
    { label: "AZ", value: network.availabilityZone },
    { label: "AMI", value: config.ami },
    { label: "Instance", value: config.instance_type },
    { label: "Public IP", value: String(config.enable_public_ip) },
    { label: "KMS Policy", value: "default (strict)" },
    {
      label: "Home Volume",
      value: config.use_volume
        ? `${config.volume_size} GiB on ${config.volume_device}`
        : "disabled",
    },
    {
      label: "SSH Key",
      value: config.public_key.startsWith("file://")
        ? "file"
        : config.public_key
        ? "inline"
        : "auto-generated",
    },
    { label: "User", value: config.username },
  ]);
}

function printOutputs(outputs: Record<string, any>): void {
  displayCard(
    "Apply Complete",
    [
      { label: "Instance ID", value: outputs.instanceId ?? "n/a" },
      { label: "Public IP", value: outputs.publicIp ?? "n/a" },
      { label: "Private IP", value: outputs.privateIp ?? "n/a" },
      { label: "KMS Key ID", value: outputs.kmsKeyId ?? "n/a" },
      { label: "KMS Key ARN", value: outputs.kmsKeyArn ?? "n/a" },
      ...(outputs.volumeId
        ? [{ label: "Volume ID", value: outputs.volumeId }]
        : []),
    ],
    120
  );
}

export async function runApply(
  name: string,
  options: { sshConfig?: boolean } = {}
): Promise<void> {
  const config = resolveConfig(name);
  const trimmedName = config.name;

  console.log(`Resolving AWS identity for profile "${config.aws_profile}"...`);
  const identity = await getCallerIdentity(
    config.aws_profile,
    config.aws_region
  );
  const normalizedCallerArn = normalizePrincipalArn(identity.arn);

  const ownerPrincipalArn =
    config.owner_principal_arn && config.owner_principal_arn.length > 0
      ? config.owner_principal_arn
      : normalizedCallerArn;

  if (
    config.owner_principal_arn &&
    config.owner_principal_arn.length > 0 &&
    config.owner_principal_arn !== normalizedCallerArn
  ) {
    console.warn(
      `\nWarning: owner_principal_arn (${config.owner_principal_arn}) differs from the current caller (${normalizedCallerArn}).`
    );
    console.warn(`The current caller may lose future KMS management access.\n`);
  }

  const resolvedRegion = await resolveAwsRegion(
    config.aws_profile,
    config.aws_region
  );

  console.log(`Resolving network in ${resolvedRegion}...`);
  const network = await resolveNetwork(config);

  const kmsPolicy = resolveKmsPolicy(config, {
    accountId: identity.accountId,
    region: resolvedRegion,
    ownerPrincipalArn,
    deletionPrincipalArns: config.kms_deletion_principal_arns,
  });

  console.log(`Resolving SSH key...`);
  const { publicKeyMaterial, privateKeyPath } = await resolvePublicKey(config);
  if (privateKeyPath) {
    console.log(`  Auto-generated key: ${privateKeyPath}`);
  }

  let appendedUserdata = config.userdata;
  if (appendedUserdata.startsWith("file://")) {
    const path = fileUrlPath(appendedUserdata);
    if (!existsSync(path)) {
      throw new Error(`Userdata file not found: ${path}`);
    }
    appendedUserdata = readFileUrl(appendedUserdata);
  }
  appendedUserdata = appendedUserdata.replaceAll("${username}", config.username);

  const bootstrapScript = generateBootstrapScript({
    username: config.username,
    publicKeyMaterial,
    useVolume: config.use_volume,
    volumeDevice: config.volume_device,
    appendedUserdata,
  });

  const rootDeviceName = await resolveAmiRootDevice(
    config.aws_profile,
    config.aws_region,
    config.ami
  );

  const resolvedConfig: ResolvedPrivateBoxConfig = {
    ...config,
    resolvedVpcId: network.vpcId,
    resolvedSubnetId: network.subnetId,
    resolvedAvailabilityZone: network.availabilityZone,
    publicKeyMaterial,
    privateKeyPath,
    resolvedUserdata: bootstrapScript,
    resolvedKmsPolicy: kmsPolicy,
    ownerPrincipalArn,
    resolvedRootDeviceName: rootDeviceName,
  };

  printApplySummary(resolvedConfig, network);

  const confirmed = await promptYesNo("\nProceed with apply?");
  if (!confirmed) {
    console.log("Aborted.");
    return;
  }

  console.log("\nInitializing Pulumi stack...");
  const program = createProgram(resolvedConfig);
  const stack = await createOrSelectStack(
    trimmedName,
    program,
    config.aws_profile,
    config.aws_region
  );

  await runPulumiPhase("Pulumi Preview", "Running preview...", (onEvent) =>
    previewStack(stack, onEvent)
  );

  const upConfirmed = await promptYesNo("\nProceed with up?");
  if (!upConfirmed) {
    console.log("Aborted.");
    return;
  }

  await runPulumiPhase(
    "Pulumi Up",
    "Running up (this may take a few minutes)...",
    (onEvent) => upStack(stack, onEvent)
  );

  const outputs = await getStackOutputs(stack);
  printOutputs(outputs);

  if (options.sshConfig) {
    const sshHost = config.enable_public_ip ? outputs.publicIp : outputs.privateIp;

    if (!sshHost) {
      console.warn("No IP address available. Skipping SSH config.");
    } else {
      let identityFile = privateKeyPath;

      if (!identityFile && config.public_key.startsWith("file://")) {
        const guessedPrivate = fileUrlPath(config.public_key).replace(/\.pub$/, "");
        if (existsSync(guessedPrivate)) {
          identityFile = guessedPrivate;
        }
      }

      if (!identityFile && config.public_key) {
        const userPath = expandHome(
          await prompt("Enter path to SSH private key for this box: ")
        );
        if (userPath && existsSync(userPath)) {
          identityFile = userPath;
        } else {
          console.warn("No valid private key path provided. Skipping SSH config.");
        }
      }

      if (identityFile) {
        appendSshConfig(trimmedName, sshHost, config.username, identityFile);
        console.log(`SSH config added for host pb-${trimmedName}`);
      }

      if (!config.enable_public_ip) {
        console.warn(
          "Public IP is disabled. SSH requires VPN/bastion/private connectivity."
        );
      }
    }
  }
}
