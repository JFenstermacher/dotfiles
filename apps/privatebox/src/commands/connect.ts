import { chmodSync, existsSync, readFileSync, writeFileSync } from "node:fs";
import { spawn } from "node:child_process";
import { join } from "node:path";
import { resolveConfig } from "../config/store.js";
import { readStackOutputs, stackExists } from "../pulumi/stack-manager.js";
import { describeInstance } from "../utils/instance.js";
import { keyDir } from "../utils/xdg.js";
import { fileUrlPath } from "../utils/path.js";
import { isPublicKeyMaterial } from "../pulumi/ssh-keys.js";

const TEMPLATE_VARIABLES = [
  "username",
  "public_ip",
  "private_ip",
  "public_key_path",
] as const;

type TemplateVariable = (typeof TEMPLATE_VARIABLES)[number];

function shellQuote(value: string): string {
  return `'${value.replace(/'/g, `'"'"'`)}'`;
}

function findTemplateVariables(template: string): Set<TemplateVariable> {
  const vars = new Set<TemplateVariable>();
  for (const match of template.matchAll(/\$\{([a-zA-Z_][a-zA-Z0-9_]*)\}/g)) {
    if ((TEMPLATE_VARIABLES as readonly string[]).includes(match[1])) {
      vars.add(match[1] as TemplateVariable);
    }
  }
  return vars;
}

function renderTemplate(
  template: string,
  values: Record<TemplateVariable, string>
): string {
  return template.replace(/\$\{([a-zA-Z_][a-zA-Z0-9_]*)\}/g, (full, key) => {
    if (!(key in values)) {
      throw new Error(
        `Unknown connect command variable ${full}. Supported variables: ${TEMPLATE_VARIABLES.map((v) => `\${${v}}`).join(", ")}`
      );
    }
    return shellQuote(values[key as TemplateVariable]);
  });
}

function publicKeyPathForConfig(name: string): string {
  return join(keyDir(name), "public_key.pub");
}

function ensurePublicKeyPath(name: string, publicKey: string): string {
  const pk = publicKey.trim();

  if (!pk) {
    const generatedPath = join(keyDir(name), "id_ed25519.pub");
    if (!existsSync(generatedPath)) {
      throw new Error(
        `public_key_path was requested, but this config uses an auto-generated key and ${generatedPath} does not exist. Run \`privatebox apply ${name}\` first.`
      );
    }
    return generatedPath;
  }

  if (pk.startsWith("file://")) {
    const path = fileUrlPath(pk);
    if (!existsSync(path)) {
      throw new Error(`Public key file not found: ${path}`);
    }
    return path;
  }

  if (isPublicKeyMaterial(pk)) {
    const path = publicKeyPathForConfig(name);
    const existing = existsSync(path) ? readFileSync(path, "utf-8") : "";
    const content = `${pk}\n`;
    if (existing !== content) {
      writeFileSync(path, content, { encoding: "utf-8", mode: 0o600 });
      chmodSync(path, 0o600);
    }
    return path;
  }

  throw new Error(
    "Invalid public_key value. Must be a file:// path, inline SSH key, or empty for auto-generation."
  );
}

export async function runConnect(name: string): Promise<void> {
  const config = resolveConfig(name);
  const trimmedName = config.name;

  if (!(await stackExists(trimmedName))) {
    throw new Error(
      `No stack found for "${trimmedName}". Run "privatebox apply ${trimmedName}" first.`
    );
  }

  const outputs = readStackOutputs(trimmedName) ?? {};
  const instanceId = outputs.instanceId as string | undefined;

  let publicIp = outputs.publicIp as string | undefined;
  let privateIp = outputs.privateIp as string | undefined;

  if (instanceId) {
    const info = await describeInstance(config, instanceId);
    publicIp = info.publicIp ?? publicIp;
    privateIp = info.privateIp ?? privateIp;
  }

  const connectCommand = config.connect_command;
  const usedVariables = findTemplateVariables(connectCommand);
  const publicKeyPath = usedVariables.has("public_key_path")
    ? ensurePublicKeyPath(trimmedName, config.public_key)
    : "";

  if (usedVariables.has("public_ip") && !publicIp) {
    throw new Error(
      `Connect command uses \${public_ip}, but no public IP is available for "${trimmedName}".`
    );
  }

  if (usedVariables.has("private_ip") && !privateIp) {
    throw new Error(
      `Connect command uses \${private_ip}, but no private IP is available for "${trimmedName}".`
    );
  }

  const rendered = renderTemplate(connectCommand, {
    username: config.username,
    public_ip: publicIp ?? "",
    private_ip: privateIp ?? "",
    public_key_path: publicKeyPath,
  });

  const child = spawn("/bin/sh", ["-c", `exec ${rendered}`], {
    stdio: "inherit",
  });

  await new Promise<void>((resolve) => {
    child.on("exit", (code, signal) => {
      if (signal) {
        process.kill(process.pid, signal);
        return;
      }
      process.exit(code ?? 0);
    });
    child.on("error", (err) => {
      console.error(`Failed to run connect command: ${err.message}`);
      process.exit(1);
    });
    child.on("close", () => resolve());
  });
}
