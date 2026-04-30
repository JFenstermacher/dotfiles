#!/bin/bash
set -euo pipefail

# ── PrivateBox bootstrap ─────────────────────────────────────────────────

PRIVATEBOX_USERNAME={{PRIVATEBOX_USERNAME}}
PRIVATEBOX_HOME_PATH="/home/${PRIVATEBOX_USERNAME}"
PRIVATEBOX_PUBLIC_KEY=$(cat <<'PRIVATEBOX_AUTHORIZED_KEY'
{{PRIVATEBOX_PUBLIC_KEY_MATERIAL}}
PRIVATEBOX_AUTHORIZED_KEY
)

# Ensure user exists
if ! id -u "$PRIVATEBOX_USERNAME" &>/dev/null; then
  useradd -m -s /bin/bash "$PRIVATEBOX_USERNAME"
fi

# Ensure home directory exists with correct ownership
mkdir -p "$PRIVATEBOX_HOME_PATH"
chown "${PRIVATEBOX_USERNAME}:${PRIVATEBOX_USERNAME}" "$PRIVATEBOX_HOME_PATH"
chmod 755 "$PRIVATEBOX_HOME_PATH"

# Grant passwordless sudo for private-box administration
if getent group wheel >/dev/null 2>&1; then
  usermod -aG wheel "$PRIVATEBOX_USERNAME"
elif getent group sudo >/dev/null 2>&1; then
  usermod -aG sudo "$PRIVATEBOX_USERNAME"
fi

cat > "/etc/sudoers.d/privatebox-${PRIVATEBOX_USERNAME}" <<PRIVATEBOX_SUDOERS
${PRIVATEBOX_USERNAME} ALL=(ALL) NOPASSWD:ALL
PRIVATEBOX_SUDOERS
chmod 0440 "/etc/sudoers.d/privatebox-${PRIVATEBOX_USERNAME}"

# Configure SSH access
mkdir -p "$PRIVATEBOX_HOME_PATH/.ssh"
chmod 700 "$PRIVATEBOX_HOME_PATH/.ssh"
printf '%s\n' "$PRIVATEBOX_PUBLIC_KEY" > "$PRIVATEBOX_HOME_PATH/.ssh/authorized_keys"
chmod 600 "$PRIVATEBOX_HOME_PATH/.ssh/authorized_keys"
chown "${PRIVATEBOX_USERNAME}:${PRIVATEBOX_USERNAME}" -R "$PRIVATEBOX_HOME_PATH/.ssh"
