import {
  EC2Client,
  DescribeInstancesCommand,
} from "@aws-sdk/client-ec2";

export function sleep(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

export async function waitForInstanceState(
  client: EC2Client,
  instanceId: string,
  targetState: "running" | "stopped",
  timeoutMs = 120_000,
  intervalMs = 5_000
): Promise<void> {
  const start = Date.now();
  while (Date.now() - start < timeoutMs) {
    const response = await client.send(
      new DescribeInstancesCommand({ InstanceIds: [instanceId] })
    );
    const state =
      response.Reservations?.[0]?.Instances?.[0]?.State?.Name ?? "unknown";
    if (state === targetState) {
      return;
    }
    if (state === "terminated" || state === "shutting-down") {
      throw new Error(
        `Instance ${instanceId} is ${state}. Cannot reach target state "${targetState}".`
      );
    }
    await sleep(intervalMs);
  }
  throw new Error(
    `Timed out after ${timeoutMs / 1000}s waiting for instance to become ${targetState}.`
  );
}