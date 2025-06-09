#!/usr/bin/env bash

set -euo pipefail

read -s -p "Enter passphrase for decrypting secrets: " PASSPHRASE
echo

export AGE_PASSPHRASE="$PASSPHRASE"

SECRET_DIR="/etc/nixos/secrets"
DEST_DIR="/home/joni/.ssh"

mkdir -p "$DEST_DIR"

for encfile in "$SECRET_DIR"/*.age; do
  [ -e "$encfile" ] || continue  # Skip if no .age files

  filename="$(basename "${encfile%.age}")"
  outfile="$DEST_DIR/$filename"

  echo "🔓 Decrypting $(basename "$encfile") → $outfile"

  age --decrypt -o "$outfile" "$encfile"
  chmod 600 "$outfile"
done

unset AGE_PASSPHRASE

echo "✅ All .age secrets decrypted to $DEST_DIR"

