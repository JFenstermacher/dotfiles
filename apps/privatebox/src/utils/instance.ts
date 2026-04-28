import {
  EC2Client,
  DescribeInstancesCommand,
  StartInstancesCommand,
  StopInstancesCommand,
} from "@aws-sdk/client-ec2";
import { fromIni } from "@aws-sdk/credential-providers";
import type { PrivateBoxConfig } from "../config/schema.js";
import { readStackOutputs, stackExists } from "../pulumi/stack-manager.js";
import { waitForInstanceState } from "./ec2-helpers.js";

export interface InstanceInfo {
  instanceId: string;
  state: string;
  publicIp?: string;
  privateIp?: string;
  launchTime?: string;
}

export function createEc2Client(config: PrivateBoxConfig): EC2Client {
  return new EC2Client({
    region: config.aws_region,
    credentials: fromIni({ profile: config.aws_profile }),
  });
}

export async function getStackInstanceId(name: string): Promise<string> {
  if (!(await stackExists(name))) {
    throw new Error(`No stack found for "${name}". Run "privatebox apply ${name}" first.`);
  }

  const outputs = readStackOutputs(name) ?? {};
  const instanceId = outputs.instanceId as string | undefined;
  if (!instanceId) {
    throw new Error(`No instance ID found in stack outputs for "${name}".`);
  }
  return instanceId;
}

export async function describeInstance(
  config: PrivateBoxConfig,
  instanceId: string
): Promise<InstanceInfo> {
  const client = createEc2Client(config);
  try {
    const desc = await client.send(
      new DescribeInstancesCommand({ InstanceIds: [instanceId] })
    );
    const instance = desc.Reservations?.[0]?.Instances?.[0];
    return {
      instanceId,
      state: instance?.State?.Name ?? "unknown",
      publicIp: instance?.PublicIpAddress,
      privateIp: instance?.PrivateIpAddress,
      launchTime: instance?.LaunchTime?.toISOString(),
    };
  } finally {
    client.destroy();
  }
}

export async function transitionInstance(args: {
  config: PrivateBoxConfig;
  instanceId: string;
  targetState: "running" | "stopped";
}): Promise<InstanceInfo> {
  const client = createEc2Client(args.config);
  try {
    if (args.targetState === "running") {
      await client.send(new StartInstancesCommand({ InstanceIds: [args.instanceId] }));
    } else {
      await client.send(new StopInstancesCommand({ InstanceIds: [args.instanceId] }));
    }
    await waitForInstanceState(client, args.instanceId, args.targetState);
  } finally {
    client.destroy();
  }

  return describeInstance(args.config, args.instanceId);
}
