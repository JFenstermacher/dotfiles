export interface BootstrapArgs {
  username: string;
  publicKeyMaterial: string;
  useVolume: boolean;
  volumeDevice: string;
  appendedUserdata: string;
}

/**
 * Generate an idempotent shell script used as EC2 userdata.
 *
 * Configures the OS user, SSH access, and optional encrypted home volume mount.
 */
export function generateBootstrapScript(args: BootstrapArgs): string {
  const lines: string[] = [
    "#!/bin/bash",
    "set -euo pipefail",
    "",
    "# ── PrivateBox bootstrap ─────────────────────────────────────────────────",
    "",
    `# Ensure user exists: ${args.username}`,
    `if ! id -u "${args.username}" &>/dev/null; then`,
    `  useradd -m -s /bin/bash "${args.username}"`,
    `fi`,
    "",
    `# Ensure home directory exists with correct ownership`,
    `mkdir -p "/home/${args.username}"`,
    `chown "${args.username}:${args.username}" "/home/${args.username}"`,
    `chmod 755 "/home/${args.username}"`,
  ];

  if (args.useVolume) {
    const device = args.volumeDevice;
    const homePath = `/home/${args.username}`;
    lines.push(
      "",
      `# ── Encrypted home volume setup ─────────────────────────────────────────`,
      `DEVICE="${device}"`,
      `HOME_PATH="${homePath}"`,
      "",
      `# Wait for the EBS volume to appear (max 60s)`,
      `for i in $(seq 1 60); do`,
      `  if [ -e "$DEVICE" ] || [ -e "$(echo $DEVICE | sed 's|/dev/sd|/dev/xvd|')" ]; then`,
      `    break`,
      `  fi`,
      `  sleep 1`,
      `done`,
      "",
      `# Resolve actual device name (sd -> xvd mapping on some instances)`,
      `ACTUAL_DEVICE="$DEVICE"`,
      `if [ ! -e "$ACTUAL_DEVICE" ]; then`,
      `  XVD_DEVICE=$(echo "$DEVICE" | sed 's|/dev/sd|/dev/xvd|')`,
      `  if [ -e "$XVD_DEVICE" ]; then`,
      `    ACTUAL_DEVICE="$XVD_DEVICE"`,
      `  fi`,
      `fi`,
      "",
      `# Format only if the device has no filesystem`,
      `if ! blkid "$ACTUAL_DEVICE" &>/dev/null; then`,
      `  mkfs -t ext4 "$ACTUAL_DEVICE"`,
      `fi`,
      "",
      `# Mount at home path`,
      `mkdir -p "$HOME_PATH"`,
      `if ! mountpoint -q "$HOME_PATH"; then`,
      `  mount "$ACTUAL_DEVICE" "$HOME_PATH"`,
      `fi`,
      "",
      `# Persist in fstab`,
      `UUID=$(blkid -s UUID -o value "$ACTUAL_DEVICE" || true)`,
      `if [ -n "$UUID" ]; then`,
      `  if ! grep -q "$UUID" /etc/fstab; then`,
      `    echo "UUID=$UUID $HOME_PATH ext4 defaults,noatime 0 0" >> /etc/fstab`,
      `  fi`,
      `elif ! grep -q "$ACTUAL_DEVICE" /etc/fstab; then`,
      `  echo "$ACTUAL_DEVICE $HOME_PATH ext4 defaults,noatime 0 0" >> /etc/fstab`,
      `fi`,
      "",
      `# Ensure correct ownership after mount`,
      `chown "${args.username}:${args.username}" "$HOME_PATH"`,
      `chmod 755 "$HOME_PATH"`
    );
  }

  const keyMaterial = args.publicKeyMaterial.trim();
  lines.push(
    "",
    `# Configure SSH access for ${args.username}`,
    `mkdir -p "/home/${args.username}/.ssh"`,
    `chmod 700 "/home/${args.username}/.ssh"`,
    `cat > "/home/${args.username}/.ssh/authorized_keys" <<'PRIVATEBOX_AUTHORIZED_KEY'`,
    keyMaterial,
    `PRIVATEBOX_AUTHORIZED_KEY`,
    `chmod 600 "/home/${args.username}/.ssh/authorized_keys"`,
    `chown "${args.username}:${args.username}" -R "/home/${args.username}/.ssh"`
  );

  if (args.appendedUserdata && args.appendedUserdata.trim().length > 0) {
    lines.push(
      "",
      "# ── User-provided userdata ──────────────────────────────────────────────",
      args.appendedUserdata.trim()
    );
  }

  return lines.join("\n");
}
