#!/usr/bin/env bash
set -euo pipefail

# Garbage collect old generations

DAYS="${1:-30}"

sudo nix-collect-garbage --delete-older-than "${DAYS}d"
sudo nix-store --optimise
