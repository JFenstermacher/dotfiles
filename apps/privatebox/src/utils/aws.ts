import { STSClient, GetCallerIdentityCommand } from "@aws-sdk/client-sts";
import { fromIni } from "@aws-sdk/credential-providers";
import { loadSharedConfigFiles } from "@smithy/shared-ini-file-loader";

// ── Profile helpers ─────────────────────────────────────────────────────────

export function getCurrentProfile(): string {
  const profile = process.env.AWS_PROFILE;
  return profile && profile.length > 0 ? profile : "default";
}

export function resolveAwsProfile(profile?: string): string {
  if (profile !== undefined && profile !== null) {
    const trimmed = profile.trim();
    if (trimmed.length === 0) {
      throw new Error("AWS profile cannot be empty");
    }
    return trimmed;
  }
  return getCurrentProfile();
}

// ── Region helpers ──────────────────────────────────────────────────────────

export async function resolveAwsRegion(
  profile?: string,
  region?: string
): Promise<string> {
  if (region && region.trim().length > 0) {
    return region.trim();
  }

  const envRegion = process.env.AWS_REGION || process.env.AWS_DEFAULT_REGION;
  if (envRegion && envRegion.length > 0) {
    return envRegion;
  }

  // Try reading from shared AWS config files
  try {
    const files = await loadSharedConfigFiles();
    const profileName = resolveAwsProfile(profile);

    const configEntry = files.configFile[profileName];
    if (configEntry?.region) {
      return configEntry.region;
    }

    // Credentials file may also contain region
    const credsEntry = files.credentialsFile[profileName];
    if (credsEntry?.region) {
      return credsEntry.region;
    }
  } catch {
    // Ignore shared config read failures and fall through to the error below
  }

  throw new Error(
    `Could not resolve AWS region for profile "${resolveAwsProfile(profile)}". ` +
      `Set AWS_REGION, AWS_DEFAULT_REGION, or a region in your AWS config file.`
  );
}

// ── Caller identity ─────────────────────────────────────────────────────────

export async function getCallerIdentity(
  profile: string,
  region?: string
): Promise<{ accountId: string; arn: string; userId: string }> {
  const resolvedRegion = await resolveAwsRegion(profile, region);

  const client = new STSClient({
    region: resolvedRegion,
    credentials: fromIni({ profile }),
  });

  try {
    const response = await client.send(new GetCallerIdentityCommand({}));
    return {
      accountId: response.Account!,
      arn: response.Arn!,
      userId: response.UserId!,
    };
  } finally {
    client.destroy();
  }
}

// ── ARN normalization ───────────────────────────────────────────────────────

/**
 * Converts STS assumed-role ARNs to durable IAM role ARNs.
 *
 * Examples:
 *   arn:aws:sts::123456789012:assumed-role/MyRole/session-name
 *     → arn:aws:iam::123456789012:role/MyRole
 *
 *   arn:aws:iam::123456789012:role/MyRole
 *     → arn:aws:iam::123456789012:role/MyRole (unchanged)
 *
 *   arn:aws:iam::123456789012:user/jdoe
 *     → arn:aws:iam::123456789012:user/jdoe (unchanged)
 */
export function normalizePrincipalArn(arn: string): string {
  const match = arn.match(
    /^arn:aws:sts::(\d{12}):assumed-role\/([^/]+)\/.+$/
  );
  if (match) {
    const [, accountId, roleName] = match;
    return `arn:aws:iam::${accountId}:role/${roleName}`;
  }
  return arn;
}
