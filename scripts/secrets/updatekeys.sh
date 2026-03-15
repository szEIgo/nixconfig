#!/usr/bin/env bash
set -euo pipefail

# Re-encrypt secrets for all hosts in .sops.yaml

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

cd "$REPO_ROOT"
sops updatekeys secrets/secrets.yaml
