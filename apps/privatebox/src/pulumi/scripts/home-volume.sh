# ── Encrypted home volume setup ─────────────────────────────────────────

DEVICE={{PRIVATEBOX_VOLUME_DEVICE}}
HOME_PATH="/home/{{PRIVATEBOX_USERNAME}}"

# Wait for the EBS volume to appear (max 60s)
for i in $(seq 1 60); do
  if [ -e "$DEVICE" ] || [ -e "$(echo "$DEVICE" | sed 's|/dev/sd|/dev/xvd|')" ]; then
    break
  fi
  sleep 1
done

# Resolve actual device name (sd -> xvd mapping on some instances)
ACTUAL_DEVICE="$DEVICE"
if [ ! -e "$ACTUAL_DEVICE" ]; then
  XVD_DEVICE=$(echo "$DEVICE" | sed 's|/dev/sd|/dev/xvd|')
  if [ -e "$XVD_DEVICE" ]; then
    ACTUAL_DEVICE="$XVD_DEVICE"
  fi
fi

# Format only if the device has no filesystem
if ! blkid "$ACTUAL_DEVICE" &>/dev/null; then
  mkfs -t ext4 "$ACTUAL_DEVICE"
fi

# Mount at home path
mkdir -p "$HOME_PATH"
if ! mountpoint -q "$HOME_PATH"; then
  mount "$ACTUAL_DEVICE" "$HOME_PATH"
fi

# Persist in fstab
UUID=$(blkid -s UUID -o value "$ACTUAL_DEVICE" || true)
if [ -n "$UUID" ]; then
  if ! grep -q "$UUID" /etc/fstab; then
    echo "UUID=$UUID $HOME_PATH ext4 defaults,noatime 0 0" >> /etc/fstab
  fi
elif ! grep -q "$ACTUAL_DEVICE" /etc/fstab; then
  echo "$ACTUAL_DEVICE $HOME_PATH ext4 defaults,noatime 0 0" >> /etc/fstab
fi

# Ensure correct ownership after mount
chown "{{PRIVATEBOX_USERNAME}}:{{PRIVATEBOX_USERNAME}}" "$HOME_PATH"
chmod 755 "$HOME_PATH"
