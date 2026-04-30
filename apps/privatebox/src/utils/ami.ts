import { SSMClient, GetParameterCommand } from "@aws-sdk/client-ssm";
import { fromIni } from "@aws-sdk/credential-providers";
import { isCredentialsError, isTimeoutError } from "./aws-errors.js";

// ── Helpers ────────────────────────────────────────────────────────────────

function isParameterNotFoundError(error: any): boolean {
  if (!error) return false;
  const name = error.name || "";
  return (
    name === "ParameterNotFound" ||
    name === "InvalidParameterException" ||
    name === "InternalServerError"
  );
}

// ── Ubuntu AMI via SSM ──────────────────────────────────────────────────────

const UBUNTU_2404_ARM64_SSM_PARAMETER =
  "/aws/service/canonical/ubuntu/server/24.04/stable/current/arm64/hvm/ebs-gp3/ami-id";

/**
 * Resolve the latest Ubuntu 24.04 LTS ARM64 AMI ID for a given AWS region via SSM.
 *
 * @param profile — AWS profile name to use for credentials
 * @param region  — AWS region to query
 * @returns AMI ID string (e.g. "ami-0abcdef1234567890")
 */
export async function getLatestUbuntu2404Arm64Ami(
  profile: string,
  region: string
): Promise<string> {
  const client = new SSMClient({
    region,
    credentials: fromIni({ profile }),
  });

  async function fetchParameter(): Promise<string> {
    const response = await client.send(
      new GetParameterCommand({ Name: UBUNTU_2404_ARM64_SSM_PARAMETER })
    );
    const amiId = response.Parameter?.Value;
    if (!amiId) {
      throw new Error(
        `SSM parameter "${UBUNTU_2404_ARM64_SSM_PARAMETER}" returned an empty value ` +
          `in region "${region}".`
      );
    }
    return amiId;
  }

  try {
    return await fetchParameter();
  } catch (error: any) {
    if (isCredentialsError(error)) {
      throw new Error(
        `AWS credentials not found for profile "${profile}". ` +
          `Ensure your credentials are configured and the profile exists.`
      );
    }

    if (isParameterNotFoundError(error)) {
      throw new Error(
        `Could not find the latest Ubuntu 24.04 LTS ARM64 AMI in region "${region}". ` +
          `The SSM parameter "${UBUNTU_2404_ARM64_SSM_PARAMETER}" may not be available ` +
          `in this region. Check your AWS region configuration.`
      );
    }

    if (isTimeoutError(error)) {
      try {
        return await fetchParameter();
      } catch {
        throw new Error(
          `Network timeout while fetching AMI from SSM after retry. ` +
            `Check your network connection and AWS connectivity.`
        );
      }
    }

    throw new Error(
      `Failed to fetch latest Ubuntu 24.04 LTS ARM64 AMI: ${error.message ?? String(error)}`
    );
  } finally {
    client.destroy();
  }
}
