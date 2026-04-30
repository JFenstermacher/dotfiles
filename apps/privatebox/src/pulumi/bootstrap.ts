import { readFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

export interface BootstrapArgs {
  username: string;
  publicKeyMaterial: string;
  useVolume: boolean;
  volumeDevice: string;
  appendedUserdata: string;
}

const SCRIPT_DIR = join(dirname(fileURLToPath(import.meta.url)), "scripts");

function loadScript(relativePath: string): string {
  return readFileSync(join(SCRIPT_DIR, relativePath), "utf8").trimEnd();
}

function renderTemplate(template: string, values: Record<string, string>): string {
  return template.replace(/{{([A-Z0-9_]+)}}/g, (_, key: string) => {
    const value = values[key];
    if (value === undefined) {
      throw new Error(`Missing bootstrap template value: ${key}`);
    }
    return value;
  });
}

/**
 * Generate an idempotent shell script used as EC2 userdata.
 *
 * Configures the OS user, SSH access, and optional encrypted home volume mount.
 */
export function generateBootstrapScript(args: BootstrapArgs): string {
  const values = {
    PRIVATEBOX_USERNAME: args.username,
    PRIVATEBOX_PUBLIC_KEY_MATERIAL: args.publicKeyMaterial.trim(),
    PRIVATEBOX_VOLUME_DEVICE: args.volumeDevice,
  };

  const scripts = [renderTemplate(loadScript("bootstrap.sh"), values)];

  if (args.useVolume) {
    scripts.push(renderTemplate(loadScript("home-volume.sh"), values));
  }

  if (args.appendedUserdata && args.appendedUserdata.trim().length > 0) {
    scripts.push(
      [
        "# ── User-provided userdata ──────────────────────────────────────────────",
        args.appendedUserdata.trim(),
      ].join("\n"),
    );
  }

  return `${scripts.join("\n\n")}\n`;
}
