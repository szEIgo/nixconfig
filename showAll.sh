#!/bin/bash

# Set base directory
NIXCONFIG_DIR="$HOME/nixconfig"
OUTPUT_FILE="$NIXCONFIG_DIR/all-configs.txt"

# Clear output file
> "$OUTPUT_FILE"

# Include specific top-level files
for file in flake.nix flake.lock; do
  if [[ -f "$NIXCONFIG_DIR/$file" ]]; then
    echo -e "\n--- $file ---" >> "$OUTPUT_FILE"
    cat "$NIXCONFIG_DIR/$file" >> "$OUTPUT_FILE"
  fi
done

# Directories to include
INCLUDE_DIRS=(home hosts modules)

# Traverse included directories
for dir in "${INCLUDE_DIRS[@]}"; do
  DIR_PATH="$NIXCONFIG_DIR/$dir"
  if [[ -d "$DIR_PATH" ]]; then
    find "$DIR_PATH" -type f \
      ! -path "$NIXCONFIG_DIR/home/configs/*" \
      ! -path "$OUTPUT_FILE" |
    while read -r filepath; do
      echo -e "\n--- ${filepath#$NIXCONFIG_DIR/} ---" >> "$OUTPUT_FILE"
      cat "$filepath" >> "$OUTPUT_FILE"
    done
  fi
done

echo "Collected content written to: $OUTPUT_FILE"
