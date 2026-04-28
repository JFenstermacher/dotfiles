import { homedir } from "node:os";
import { join } from "node:path";
import { configExists, resolveConfig, saveConfig } from "../config/store.js";
import { validateName } from "../config/validation.js";
import { resolveAwsProfile, resolveAwsRegion } from "../utils/aws.js";
import { getLatestAmazonLinux2Ami } from "../utils/ami.js";
import { runEditorValidationLoop } from "../utils/editor-validation.js";
import { cacheDir, configPath } from "../utils/xdg.js";
import { stringifyYaml } from "../config/yaml.js";

// ── Scaffold generation (no name field) ─────────────────────────────────────

function generateScaffold(args: {
  ami: string;
  awsProfile: string;
  awsRegion: string;
  publicKey: string;
  skipAmi?: boolean;
}): string {
  const config: Record<string, unknown> = {
    ami: args.skipAmi ? "# TODO: fill in AMI ID" : args.ami,
    instance_type: "t3.medium",
    aws_profile: args.awsProfile,
    aws_region: args.awsRegion,
    username: "ec2-user",
    owner_principal_arn: "",
    kms_deletion_principal_arns: [],
    kms_deletion_window_days: 30,
    vpc_id: "",
    subnet_id: "",
    enable_public_ip: true,
    ingress: [],
    egress: [
      {
        name: "allow-all-out",
        description: "Allow all outbound traffic",
        protocol: "-1",
        from_port: 0,
        to_port: 65535,
        ipv4_cidrs: ["0.0.0.0/0"],
        ipv6_cidrs: ["::/0"],
      },
    ],
    use_volume: false,
    volume_size: 20,
    volume_device: "/dev/sdf",
    public_key: args.publicKey,
    userdata: "",
  };

  return stringifyYaml(config);
}

// ── Main command ────────────────────────────────────────────────────────────

export async function runConfigure(options: {
  fromName?: string;
  name: string;
  skipAmi?: boolean;
}): Promise<void> {
  const name = options.name.trim();

  // ── Up-front validation (before any AWS calls or editor) ────────────────
  if (!validateName(name)) {
    throw new Error(
      `Invalid config name: "${name}". Names must start with a letter and contain only letters, numbers, underscores, and hyphens.`
    );
  }

  if (configExists(name)) {
    throw new Error(
      `Config "${name}" already exists. Choose a different name or edit it with \`privatebox edit ${name}\`.`
    );
  }

  const profile = resolveAwsProfile();
  const region = await resolveAwsRegion(profile);
  const draftPath = join(cacheDir(), "configure-draft.yml");

  if (options.fromName) {
    // ── --from mode ────────────────────────────────────────────────────────
    if (!configExists(options.fromName)) {
      throw new Error(`Source config "${options.fromName}" does not exist.`);
    }

    const sourceConfig = resolveConfig(options.fromName);

    // Resolve latest AMI for current region (unless --skip-ami)
    let latestAmi: string;
    if (options.skipAmi) {
      latestAmi = "# TODO: fill in AMI ID";
    } else {
      try {
        latestAmi = await getLatestAmazonLinux2Ami(profile, region);
      } catch (err) {
        throw new Error(
          `Failed to resolve latest AMI: ${err instanceof Error ? err.message : String(err)}`
        );
      }
    }

    // Build draft without the name field; override profile/region/ami
    const { name: _sourceName, ...sourceWithoutName } = sourceConfig;
    const draft = {
      ...sourceWithoutName,
      aws_profile: profile,
      aws_region: region,
      ami: latestAmi,
    };

    const draftYaml = stringifyYaml(draft);

    console.log(`Creating config "${name}" from "${options.fromName}"...`);

    const config = await runEditorValidationLoop(draftYaml, draftPath, { injectName: name });
    if (!config) {
      console.log("Aborted. No config was saved.");
      return;
    }

    saveConfig(config);
    console.log(`Config saved: ${configPath(config.name)}`);
    return;
  }

  // ── Fresh mode ───────────────────────────────────────────────────────────
  let latestAmi: string;
  if (options.skipAmi) {
    latestAmi = "# TODO: fill in AMI ID";
  } else {
    try {
      latestAmi = await getLatestAmazonLinux2Ami(profile, region);
    } catch (err) {
      throw new Error(
        `Failed to resolve latest AMI: ${err instanceof Error ? err.message : String(err)}`
      );
    }
  }

  const publicKeyDefault = `file://${homedir()}/.ssh/id_ed25519.pub`;
  const scaffoldYaml = generateScaffold({
    ami: latestAmi,
    awsProfile: profile,
    awsRegion: region,
    publicKey: publicKeyDefault,
    skipAmi: options.skipAmi,
  });

  console.log(`Creating new config "${name}"...`);
  const config = await runEditorValidationLoop(scaffoldYaml, draftPath, { injectName: name });
  if (!config) {
    console.log("Aborted. No config was saved.");
    return;
  }

  saveConfig(config);
  console.log(`Config saved: ${configPath(config.name)}`);
}
