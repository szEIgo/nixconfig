#!/usr/bin/env bash
set -euo pipefail

# Initialize flux sops-age secret from local age key
# Requires: age key at ~/.config/sops/keys/age.key

export KUBECONFIG="${KUBECONFIG:-$HOME/.kube/config}"
AGE_KEY="${AGE_KEY:-$HOME/.config/sops/keys/age.key}"
FLUX_NAMESPACE="${FLUX_NAMESPACE:-flux-system}"

if [[ ! -f "$AGE_KEY" ]]; then
    echo "ERROR: Age key not found at $AGE_KEY"
    echo "Create one with: age-keygen -o $AGE_KEY"
    exit 1
fi

echo "[flux-init] Creating namespace $FLUX_NAMESPACE"
kubectl create namespace "$FLUX_NAMESPACE" 2>/dev/null || true

echo "[flux-init] Creating sops-age secret"
kubectl create secret generic sops-age \
    --from-file=age.agekey="$AGE_KEY" \
    -n "$FLUX_NAMESPACE" \
    --dry-run=client -o yaml | kubectl apply -f -

echo "[flux-init] Done"
echo "Public key: $(age-keygen -y "$AGE_KEY")"
