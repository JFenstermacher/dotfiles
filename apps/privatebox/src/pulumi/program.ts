import * as pulumi from "@pulumi/pulumi";
import { PulumiFn } from "@pulumi/pulumi/automation";
import * as aws_native from "@pulumi/aws-native";
import type { PrivateBoxConfig, SecurityGroupRule } from "../config/schema.js";

export interface ResolvedPrivateBoxConfig extends PrivateBoxConfig {
  resolvedVpcId: string;
  resolvedSubnetId: string;
  resolvedAvailabilityZone: string;
  publicKeyMaterial: string;
  privateKeyPath?: string;
  resolvedUserdata: string;
  resolvedKmsPolicy: string;
  ownerPrincipalArn: string;
  resolvedRootDeviceName?: string;
}

type Tag = { key: string; value: string };

function interpolateDescription(
  template: string,
  name: string
): string {
  return template.replace(/{name}/g, name);
}

type SecurityGroupRuleResource =
  | aws_native.ec2.SecurityGroupIngress
  | aws_native.ec2.SecurityGroupEgress;

function createSecurityGroupRules(args: {
  name: string;
  groupId: pulumi.Input<string>;
  direction: "ingress" | "egress";
  rules: SecurityGroupRule[];
}): SecurityGroupRuleResource[] {
  const resources: SecurityGroupRuleResource[] = [];
  const Resource =
    args.direction === "ingress"
      ? aws_native.ec2.SecurityGroupIngress
      : aws_native.ec2.SecurityGroupEgress;

  for (let i = 0; i < args.rules.length; i++) {
    const rule = args.rules[i];
    for (const cidr of rule.ipv4_cidrs) {
      resources.push(
        new Resource(`${args.name}-${args.direction}-${i}-ipv4`, {
          groupId: args.groupId,
          ipProtocol: rule.protocol,
          fromPort: rule.from_port,
          toPort: rule.to_port,
          cidrIp: cidr,
          description: rule.description,
        } as any)
      );
    }
    for (const cidr of rule.ipv6_cidrs) {
      resources.push(
        new Resource(`${args.name}-${args.direction}-${i}-ipv6`, {
          groupId: args.groupId,
          ipProtocol: rule.protocol,
          fromPort: rule.from_port,
          toPort: rule.to_port,
          cidrIpv6: cidr,
          description: rule.description,
        } as any)
      );
    }
  }

  return resources;
}

function createHomeVolume(
  config: ResolvedPrivateBoxConfig,
  kmsKeyArn: pulumi.Input<string>,
  tags: Tag[]
): aws_native.ec2.Volume | undefined {
  if (!config.use_volume) return undefined;

  return new aws_native.ec2.Volume(`${config.name}-volume`, {
    availabilityZone: config.resolvedAvailabilityZone,
    size: config.volume_size,
    encrypted: true,
    kmsKeyId: kmsKeyArn,
    volumeType: "gp3",
    tags,
  });
}

function createInstance(args: {
  config: ResolvedPrivateBoxConfig;
  securityGroupId: pulumi.Input<string>;
  keyName: pulumi.Input<string>;
  kmsKeyArn: pulumi.Input<string>;
  tags: Tag[];
}): aws_native.ec2.Instance {
  const rootDevice = args.config.resolvedRootDeviceName ?? "/dev/xvda";
  const userDataBase64 = Buffer.from(args.config.resolvedUserdata).toString(
    "base64"
  );

  return new aws_native.ec2.Instance(`${args.config.name}-instance`, {
    imageId: args.config.ami,
    instanceType: args.config.instance_type,
    networkInterfaces: [
      {
        deviceIndex: "0",
        subnetId: args.config.resolvedSubnetId,
        groupSet: [args.securityGroupId],
        associatePublicIpAddress: args.config.enable_public_ip,
        deleteOnTermination: true,
      },
    ],
    keyName: args.keyName,
    userData: userDataBase64,
    blockDeviceMappings: [
      {
        deviceName: rootDevice,
        ebs: {
          encrypted: true,
          kmsKeyId: args.kmsKeyArn,
          deleteOnTermination: true,
          volumeSize: 8,
          volumeType: "gp3",
        },
      },
    ],
    tags: args.tags,
  });
}

export function createProgram(config: ResolvedPrivateBoxConfig): PulumiFn {
  return async () => {
    const commonTags = [
      { key: "Name", value: config.name },
      { key: "privatebox", value: "true" },
    ];

    const kmsKey = new aws_native.kms.Key(`${config.name}-key`, {
      description: interpolateDescription(
        config.kms_key_description,
        config.name
      ),
      keyPolicy: JSON.parse(config.resolvedKmsPolicy),
      pendingWindowInDays: config.kms_deletion_window_days,
      tags: commonTags,
    });

    const sg = new aws_native.ec2.SecurityGroup(`${config.name}-sg`, {
      groupDescription: interpolateDescription(
        config.security_group_description,
        config.name
      ),
      vpcId: config.resolvedVpcId,
      tags: commonTags,
    });

    createSecurityGroupRules({
      name: config.name,
      groupId: sg.groupId,
      direction: "ingress",
      rules: config.ingress,
    });
    createSecurityGroupRules({
      name: config.name,
      groupId: sg.groupId,
      direction: "egress",
      rules: config.egress,
    });

    const keyPair = new aws_native.ec2.KeyPair(`${config.name}-keypair`, {
      keyName: `${config.name}-key`,
      publicKeyMaterial: config.publicKeyMaterial,
      tags: commonTags,
    });

    const homeVolume = createHomeVolume(config, kmsKey.arn, commonTags);

    const instance = createInstance({
      config,
      securityGroupId: sg.groupId,
      keyName: keyPair.keyName,
      kmsKeyArn: kmsKey.arn,
      tags: commonTags,
    });

    if (homeVolume) {
      new aws_native.ec2.VolumeAttachment(`${config.name}-vol-attach`, {
        instanceId: instance.instanceId,
        volumeId: homeVolume.volumeId,
        device: config.volume_device,
      });
    }

    return {
      instanceId: instance.instanceId,
      publicIp: instance.publicIp,
      privateIp: instance.privateIp,
      securityGroupId: sg.groupId,
      keyPairId: keyPair.keyPairId,
      keyPairName: keyPair.keyName,
      vpcId: config.resolvedVpcId,
      subnetId: config.resolvedSubnetId,
      availabilityZone: config.resolvedAvailabilityZone,
      enablePublicIp: config.enable_public_ip,
      awsRegion: config.aws_region,
      awsProfile: config.aws_profile,
      volumeId: homeVolume ? homeVolume.volumeId : undefined,
      kmsKeyId: kmsKey.keyId,
      kmsKeyArn: kmsKey.arn,
      privateKeyPath: config.privateKeyPath,
    };
  };
}
