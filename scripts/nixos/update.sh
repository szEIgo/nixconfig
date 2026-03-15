#!/usr/bin/env bash
set -euo pipefail

# Update flake inputs and rebuild

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
HOST="${1:-mothership}"

cd "$REPO_ROOT"
nix flake update
sudo nixos-rebuild switch --flake "$REPO_ROOT#$HOST"
