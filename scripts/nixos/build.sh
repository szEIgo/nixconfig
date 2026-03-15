#!/usr/bin/env bash
set -euo pipefail

# Build NixOS configuration without switching

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
HOST="${1:-mothership}"

nixos-rebuild build --flake "$REPO_ROOT#$HOST"
