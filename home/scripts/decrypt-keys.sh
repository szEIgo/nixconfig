#!/usr/bin/env bash
set -euo pipefail

# Config paths
MASTER_KEY_ENC="../../secrets/id_mothership.age"
MASTER_KEY_DEC="/tmp/id_mothership"
SECRET_DIR="../../secrets"
SSH_DEST="$HOME/.ssh"
WG_DEST="/etc/secrets"

# Ensure dirs exist
mkdir -p "$SSH_DEST"
sudo mkdir -p "$WG_DEST"

# Step 1: Decrypt master key (prompts for passphrase, no --identity!)
echo "🔐 Decrypting master key ($MASTER_KEY_ENC)"
age --decrypt -o "$MASTER_KEY_DEC" "$MASTER_KEY_ENC"
chmod 600 "$MASTER_KEY_DEC"
chown "$USER" "$MASTER_KEY_DEC"

# Step 2: Decrypt secrets using master key
for encfile in "$SECRET_DIR"/*.age; do
  [ "$encfile" = "$MASTER_KEY_ENC" ] && continue
  [ -e "$encfile" ] || continue

  filename="$(basename "${encfile%.age}")"

  # Determine target dir
  if [[ "$filename" == id_* || "$filename" == "mothership" ]]; then
    dest="$SSH_DEST/$filename"
    echo "🔓 Decrypting SSH key $filename → $dest"
    age --identity "$MASTER_KEY_DEC" --decrypt -o "$dest" "$encfile"
    chmod 600 "$dest"
    chown "$USER" "$dest"
  elif [[ "$filename" == mothership_wg_* ]]; then
    dest="$WG_DEST/$filename"
    echo "🔓 Decrypting WireGuard key $filename → $dest (as root)"
    sudo age --identity "$MASTER_KEY_DEC" --decrypt -o "$dest" "$encfile"
    sudo chmod 600 "$dest"
    sudo chown systemd-network:systemd-network "$dest"
  else
    echo "⚠️ Unknown .age file type: $filename, skipping"
  fi
done

# Step 3: Remove master key from disk
shred -u "$MASTER_KEY_DEC"

# Step 4: Copy .pub files
for pubfile in "$SECRET_DIR"/*.pub; do
  [ -e "$pubfile" ] || continue
  cp "$pubfile" "$SSH_DEST/$(basename "$pubfile")"
  chmod 644 "$SSH_DEST/$(basename "$pubfile")"
  echo "📤 Copied $(basename "$pubfile") → $SSH_DEST"
done

echo "✅ All secrets decrypted and placed securely."
