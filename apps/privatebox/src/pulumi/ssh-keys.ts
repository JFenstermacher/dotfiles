import { existsSync, readFileSync, writeFileSync, chmodSync } from "node:fs";
import { spawnSync } from "node:child_process";
import { join } from "node:path";
import { keyDir } from "../utils/xdg.js";
import { fileUrlPath } from "../utils/path.js";
import type { PrivateBoxConfig } from "../config/schema.js";

// ── Public key detection ───────────────────────────────────────────────────

export function isPublicKeyMaterial(value: string): boolean {
  const trimmed = value.trim();
  return /^ssh-(rsa|ed25519|dss|ecdsa)\s+/.test(trimmed);
}

// ── Key pair generation ────────────────────────────────────────────────────

export async function generateKeyPair(name: string): Promise<{
  publicKeyMaterial: string;
  privateKeyPath: string;
}> {
  const dir = keyDir(name);
  const privateKeyPath = join(dir, "id_ed25519");
  const publicKeyPath = join(dir, "id_ed25519.pub");
  const infoPath = join(dir, ".info.json");

  // Idempotent: reuse existing key
  if (existsSync(privateKeyPath)) {
    const publicKeyMaterial = readFileSync(publicKeyPath, "utf-8").trim();
    return { publicKeyMaterial, privateKeyPath };
  }

  const result = spawnSync(
    "ssh-keygen",
    ["-t", "ed25519", "-f", privateKeyPath, "-N", "", "-C", `privatebox-${name}`],
    { encoding: "utf-8" }
  );

  if (result.error) {
    throw new Error(`Failed to spawn ssh-keygen: ${result.error.message}`);
  }
  if (result.status !== 0) {
    throw new Error(`ssh-keygen failed: ${result.stderr || "unknown error"}`);
  }

  // Permissions: dir 0700, private key 0600
  chmodSync(dir, 0o700);
  chmodSync(privateKeyPath, 0o600);

  // Compute fingerprint
  let fingerprint = "";
  try {
    const fpResult = spawnSync(
      "ssh-keygen",
      ["-lf", publicKeyPath],
      { encoding: "utf-8" }
    );
    if (fpResult.status === 0 && fpResult.stdout) {
      // Output format: "256 SHA256:... comment (ED25519)"
      fingerprint = fpResult.stdout.trim().split(/\s+/).slice(0, 2).join(" ");
    }
  } catch {
    // leave fingerprint empty on failure
  }

  // Metadata
  const info = {
    configName: name,
    createdAt: new Date().toISOString(),
    keyType: "ed25519",
    fingerprint,
  };
  writeFileSync(infoPath, JSON.stringify(info, null, 2), "utf-8");

  const publicKeyMaterial = readFileSync(publicKeyPath, "utf-8").trim();
  return { publicKeyMaterial, privateKeyPath };
}

// ── Public key resolution ──────────────────────────────────────────────────

export async function resolvePublicKey(
  config: PrivateBoxConfig
): Promise<{ publicKeyMaterial: string; privateKeyPath?: string }> {
  const pk = config.public_key.trim();

  // Mode 3: auto-generate
  if (!pk) {
    return generateKeyPair(config.name);
  }

  // Mode 1: file reference
  if (pk.startsWith("file://")) {
    const path = fileUrlPath(pk);
    if (!existsSync(path)) {
      throw new Error(`Public key file not found: ${path}`);
    }
    const content = readFileSync(path, "utf-8").trim();
    if (!isPublicKeyMaterial(content)) {
      throw new Error(
        `File does not contain valid SSH public key material: ${path}`
      );
    }
    return { publicKeyMaterial: content };
  }

  // Mode 2: inline key
  if (isPublicKeyMaterial(pk)) {
    return { publicKeyMaterial: pk };
  }

  throw new Error(
    `Invalid public_key value. Must be a file:// path, inline SSH key, or empty for auto-generation.`
  );
}
