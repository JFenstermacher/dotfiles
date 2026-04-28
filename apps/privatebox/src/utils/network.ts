import {
  EC2Client,
  DescribeVpcsCommand,
  DescribeSubnetsCommand,
  DescribeImagesCommand,
} from "@aws-sdk/client-ec2";
import { fromIni } from "@aws-sdk/credential-providers";
import type { PrivateBoxConfig } from "../config/schema.js";
import { stackExists, readStackOutputs } from "../pulumi/stack-manager.js";
import { isCredentialsError, isTimeoutError } from "./aws-errors.js";

export interface ResolvedNetwork {
  awsRegion: string;
  vpcId: string;
  subnetId: string;
  availabilityZone: string;
  enablePublicIp: boolean;
}

// ── VPC resolution ──────────────────────────────────────────────────────────

async function resolveDefaultVpc(
  client: EC2Client,
  region: string
): Promise<string> {
  try {
    const response = await client.send(
      new DescribeVpcsCommand({
        Filters: [{ Name: "is-default", Values: ["true"] }],
      })
    );
    const vpc = response.Vpcs?.[0];
    if (!vpc || !vpc.VpcId) {
      throw new Error(`No default VPC found in region "${region}".`);
    }
    return vpc.VpcId;
  } catch (error: any) {
    if (isCredentialsError(error)) {
      throw new Error(
        `AWS credentials not found. Ensure your credentials are configured.`
      );
    }
    throw error;
  }
}

// ── Subnet resolution ───────────────────────────────────────────────────────

async function resolveSubnet(
  client: EC2Client,
  vpcId: string,
  preferPublicIp: boolean,
  explicitSubnetId?: string
): Promise<{ subnetId: string; availabilityZone: string }> {
  if (explicitSubnetId) {
    const response = await client.send(
      new DescribeSubnetsCommand({
        SubnetIds: [explicitSubnetId],
      })
    );
    const subnet = response.Subnets?.[0];
    if (!subnet || !subnet.SubnetId || !subnet.AvailabilityZone) {
      throw new Error(`Subnet "${explicitSubnetId}" not found.`);
    }
    if (subnet.VpcId !== vpcId) {
      throw new Error(
        `Subnet "${explicitSubnetId}" does not belong to VPC "${vpcId}".`
      );
    }
    return {
      subnetId: subnet.SubnetId,
      availabilityZone: subnet.AvailabilityZone,
    };
  }

  // No explicit subnet — choose one from the VPC
  const response = await client.send(
    new DescribeSubnetsCommand({
      Filters: [{ Name: "vpc-id", Values: [vpcId] }],
    })
  );

  const subnets = response.Subnets ?? [];
  if (subnets.length === 0) {
    throw new Error(`No subnets found in VPC "${vpcId}".`);
  }

  // Prefer a subnet that auto-assigns public IPs when enable_public_ip=true
  if (preferPublicIp) {
    const publicSubnet = subnets.find(
      (s) => s.MapPublicIpOnLaunch && s.SubnetId && s.AvailabilityZone
    );
    if (publicSubnet) {
      return {
        subnetId: publicSubnet.SubnetId!,
        availabilityZone: publicSubnet.AvailabilityZone!,
      };
    }
  }

  // Fallback: first available subnet
  const subnet = subnets.find((s) => s.SubnetId && s.AvailabilityZone);
  if (!subnet) {
    throw new Error(`No valid subnets found in VPC "${vpcId}".`);
  }
  return {
    subnetId: subnet.SubnetId!,
    availabilityZone: subnet.AvailabilityZone!,
  };
}

// ── AMI root device resolution ──────────────────────────────────────────────

/**
 * Resolve the root device name for an AMI.
 * Defaults to `/dev/xvda` (Amazon Linux 2 standard) if lookup fails.
 */
export async function resolveAmiRootDevice(
  profile: string,
  region: string,
  amiId: string
): Promise<string> {
  const client = new EC2Client({
    region,
    credentials: fromIni({ profile }),
  });

  try {
    const response = await client.send(
      new DescribeImagesCommand({
        ImageIds: [amiId],
      })
    );
    const image = response.Images?.[0];
    if (image?.RootDeviceName) {
      return image.RootDeviceName;
    }
    return "/dev/xvda";
  } catch (error: any) {
    if (isTimeoutError(error)) {
      try {
        const response = await client.send(
          new DescribeImagesCommand({
            ImageIds: [amiId],
          })
        );
        const image = response.Images?.[0];
        if (image?.RootDeviceName) {
          return image.RootDeviceName;
        }
      } catch {
        // fall through to default
      }
    }
    return "/dev/xvda";
  } finally {
    client.destroy();
  }
}

// ── Stack output helpers for AZ change guard ────────────────────────────────

async function getExistingStackSubnetAndAz(
  name: string
): Promise<{ subnetId?: string; availabilityZone?: string; volumeId?: string } | undefined> {
  if (!(await stackExists(name))) {
    return undefined;
  }

  const outputs = readStackOutputs(name);
  if (!outputs) return undefined;
  return {
    subnetId: outputs.subnetId,
    availabilityZone: outputs.availabilityZone,
    volumeId: outputs.volumeId,
  };
}

// ── Public API ──────────────────────────────────────────────────────────────

/**
 * Resolve the concrete AWS region, VPC, subnet, and availability zone used by
 * a box before Pulumi apply.
 *
 * If a stack already exists with a home volume, this function reuses the
 * existing subnet/AZ and blocks accidental AZ changes.
 */
export async function resolveNetwork(
  config: PrivateBoxConfig
): Promise<ResolvedNetwork> {
  const region = config.aws_region;
  const profile = config.aws_profile;

  const client = new EC2Client({
    region,
    credentials: fromIni({ profile }),
  });

  try {
    const vpcId =
      config.vpc_id && config.vpc_id.length > 0
        ? config.vpc_id
        : await resolveDefaultVpc(client, region);

    const { subnetId, availabilityZone } = await resolveSubnet(
      client,
      vpcId,
      config.enable_public_ip,
      config.subnet_id || undefined
    );

    // AZ change guard for existing home volumes
    const existing = await getExistingStackSubnetAndAz(config.name);
    if (existing?.volumeId && existing.availabilityZone) {
      if (availabilityZone !== existing.availabilityZone) {
        throw new Error(
          `Cannot change Availability Zone while a home volume exists. ` +
            `Current AZ: ${existing.availabilityZone}, requested AZ: ${availabilityZone}. ` +
            `To migrate, destroy the box first (this will delete the home volume).`
        );
      }
      // Reuse the existing subnet if the AZ matches — preserves consistency
      return {
        awsRegion: region,
        vpcId,
        subnetId: existing.subnetId ?? subnetId,
        availabilityZone: existing.availabilityZone,
        enablePublicIp: config.enable_public_ip,
      };
    }

    return {
      awsRegion: region,
      vpcId,
      subnetId,
      availabilityZone,
      enablePublicIp: config.enable_public_ip,
    };
  } finally {
    client.destroy();
  }
}
