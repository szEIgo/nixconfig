#!/usr/bin/env bash

set -euo pipefail

MASTER_KEY_ENC="../../secrets/id_mothership.age"
MASTER_KEY_DEC="/tmp/id_mothership"

SECRET_DIR="../../secrets"
DEST_DIR="/home/joni/.ssh"

mkdir -p "$DEST_DIR"


age --decrypt -o "$MASTER_KEY_DEC" "$MASTER_KEY_ENC"
chown $USER "$MASTER_KEY_DEC" 
chmod 600 "$MASTER_KEY_DEC"

for encfile in "$SECRET_DIR"/*.age; do
  [ "$encfile" = "$MASTER_KEY_ENC" ] && continue

  [ -e "$encfile" ] || continue

  filename="$(basename "${encfile%.age}")"
  outfile="$DEST_DIR/$filename"

  echo "Decrypting $(basename "$encfile") → $outfile"

  age --identity "$MASTER_KEY_DEC" --decrypt -o "$outfile" "$encfile"
  chown $USER "$outfile" 
  chmod 600 "$outfile"
done


shred -u "$MASTER_KEY_DEC"

for pubFile in "$SECRET_DIR"/*.pub; do
  [ -e "$pubFile" ] || continue
  cp "$pubFile" "$DEST_DIR/$(basename "$pubFile")"
  chmod 644 "$DEST_DIR/$(basename "$pubFile")"
  echo "Copied $(basename "$pubFile") → $DEST_DIR"
done
echo "All SSH keys should be decrypted to $DEST_DIR"
