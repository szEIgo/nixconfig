#!/usr/bin/env bash
set -euo pipefail

# Build NixOS configuration without switching

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
HOST="${1:-mothership}"

# Memory management: limit parallel builds to avoid OOM
NIX_JOBS="${NIX_JOBS:-2}"       # Max parallel builds (low to reduce mkfs.erofs memory)
NIX_CORES="${NIX_CORES:-8}"     # Cores per build
NIX_OPTS="--max-jobs $NIX_JOBS --cores $NIX_CORES"

# Limit Nix evaluator memory (in bytes, ~8GB)
export GC_INITIAL_HEAP_SIZE="${GC_INITIAL_HEAP_SIZE:-8000000000}"

echo "Building NixOS configuration for: $HOST"
echo "Using: $NIX_JOBS parallel jobs, $NIX_CORES cores each"
nixos-rebuild build --flake "$REPO_ROOT#$HOST" $NIX_OPTS
