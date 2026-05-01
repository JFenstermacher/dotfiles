import { z } from "zod";

// ── Validation helpers ──────────────────────────────────────────────────────

const LINUX_USERNAME_REGEX = /^[a-z_][a-z0-9_-]{0,31}$/;
export const CONFIG_NAME_REGEX = /^[a-zA-Z][a-zA-Z0-9_-]{0,63}$/;
const AMI_REGEX = /^ami-[a-f0-9]{17}$/i;
const ARN_REGEX = /^arn:aws:[a-z]+::\d{12}:[a-zA-Z0-9+=,.@_/-]+$/;

function isValidIPv4Cidr(cidr: string): boolean {
  const [ip, prefix] = cidr.split("/");
  if (!ip || !prefix) return false;
  const prefixNum = Number(prefix);
  if (Number.isNaN(prefixNum) || prefixNum < 0 || prefixNum > 32) return false;
  const parts = ip.split(".");
  if (parts.length !== 4) return false;
  return parts.every((p) => {
    const n = Number(p);
    return !Number.isNaN(n) && n >= 0 && n <= 255;
  });
}

function isValidIPv6Cidr(cidr: string): boolean {
  const [ip, prefix] = cidr.split("/");
  if (!ip || !prefix) return false;
  const prefixNum = Number(prefix);
  if (Number.isNaN(prefixNum) || prefixNum < 0 || prefixNum > 128) return false;
  if (!ip.includes(":")) return false;
  return /^[0-9a-fA-F:]+$/.test(ip);
}

const defaultEgressRule = {
  name: "allow-all-out",
  description: "Allow all outbound traffic",
  protocol: "-1" as const,
  from_port: 0,
  to_port: 65535,
  ipv4_cidrs: ["0.0.0.0/0"] as string[],
  ipv6_cidrs: ["::/0"] as string[],
};

// ── Security group rule ─────────────────────────────────────────────────────

export const SecurityGroupRuleObjectSchema = z.object({
  name: z.string().min(1, "Rule name is required"),
  description: z.string(),
  protocol: z.enum(["tcp", "udp", "icmp", "-1"]).default("tcp"),
  from_port: z.number().int().min(-1).max(65535),
  to_port: z.number().int().min(-1).max(65535),
  ipv4_cidrs: z
    .array(z.string().refine(isValidIPv4Cidr, { message: "Invalid IPv4 CIDR" }))
    .default([]),
  ipv6_cidrs: z
    .array(z.string().refine(isValidIPv6Cidr, { message: "Invalid IPv6 CIDR" }))
    .default([]),
});

export const SecurityGroupRuleSchema = SecurityGroupRuleObjectSchema.refine(
  (rule) => rule.from_port <= rule.to_port,
  {
    message: "from_port must be less than or equal to to_port",
    path: ["from_port"],
  }
)
  .refine(
    (rule) => {
      if (rule.protocol === "icmp") {
        return (
          rule.from_port >= -1 &&
          rule.from_port <= 255 &&
          rule.to_port >= -1 &&
          rule.to_port <= 255
        );
      }
      return true;
    },
    {
      message:
        "icmp protocol requires from_port and to_port between -1 and 255",
      path: ["protocol"],
    }
  )
  .refine(
    (rule) => {
      if (rule.protocol === "tcp" || rule.protocol === "udp") {
        return rule.from_port >= 0 && rule.to_port >= 0;
      }
      return true;
    },
    {
      message: "tcp/udp protocols require from_port and to_port to be >= 0",
      path: ["from_port"],
    }
  );

export type SecurityGroupRule = z.infer<typeof SecurityGroupRuleObjectSchema>;

// ── Private box config ──────────────────────────────────────────────────────

export const PrivateBoxConfigObjectSchema = z.object({
  name: z
    .string()
    .min(1, "Name is required")
    .regex(
      CONFIG_NAME_REGEX,
      "Name must start with a letter and contain only letters, numbers, underscores, and hyphens"
    ),
  ami: z
    .string()
    .regex(
      AMI_REGEX,
      "Must be a valid AMI ID (ami-xxxxxxxxxxxxxxxx)"
    ),
  instance_type: z.string().min(1, "Instance type is required"),
  aws_profile: z.string().min(1, "AWS profile is required"),
  aws_region: z.string().min(1, "AWS region is required"),
  username: z
    .string()
    .regex(LINUX_USERNAME_REGEX, "Invalid Linux username")
    .default("ubuntu"),
  owner_principal_arn: z.string().default(""),
  kms_deletion_principal_arns: z
    .array(z.string().regex(ARN_REGEX, "Must be a valid IAM ARN"))
    .default([]),
  kms_deletion_window_days: z.number().int().min(7).max(30).default(30),
  vpc_id: z.string().default(""),
  subnet_id: z.string().default(""),
  enable_public_ip: z.boolean().default(true),
  ingress: z.array(SecurityGroupRuleSchema).default([]),
  egress: z.array(SecurityGroupRuleSchema).default([defaultEgressRule]),
  use_volume: z.boolean().default(false),
  volume_size: z.number().int().positive().default(20),
  volume_device: z.string().default("/dev/sdf"),
  public_key: z.string().default(""),
  connect_command: z.string().min(1, "Connect command is required").default("ssh ${username}@${public_ip}"),
  userdata: z.string().default(""),
  kms_key_description: z
    .string()
    .default("PrivateBox encryption key for {name}"),
  security_group_description: z
    .string()
    .default("Security group for private box {name}"),
});

export const PrivateBoxConfigSchema = PrivateBoxConfigObjectSchema.refine(
  (data) => {
    if (data.use_volume) {
      return data.volume_size > 0;
    }
    return true;
  },
  {
    message: "volume_size must be a positive integer when use_volume is true",
    path: ["volume_size"],
  }
);

export type PrivateBoxConfig = z.infer<typeof PrivateBoxConfigSchema>;
