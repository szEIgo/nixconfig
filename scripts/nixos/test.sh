#!/usr/bin/env bash
set -euo pipefail

# Build and activate NixOS configuration without adding to bootloader

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
HOST="${1:-mothership}"

sudo nixos-rebuild test --flake "$REPO_ROOT#$HOST"
