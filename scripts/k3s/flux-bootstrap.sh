#!/usr/bin/env bash
set -euo pipefail

# Bootstrap Flux CD from flux-system repository
# Requires: sops-age secret (run make k3s-flux-init first)
# Requires: GITHUB_TOKEN env var or encrypted token in flux-system repo

export KUBECONFIG="${KUBECONFIG:-$HOME/.kube/config}"
AGE_KEY="${AGE_KEY:-$HOME/.config/sops/keys/age.key}"
FLUX_NAMESPACE="${FLUX_NAMESPACE:-flux-system}"

# Flux-system repo settings
FLUX_REPO="${FLUX_REPO:-$HOME/flux-system}"
GITHUB_OWNER="${GITHUB_OWNER:-szeigo}"
GITHUB_REPO="${GITHUB_REPO:-flux-system}"
GITHUB_BRANCH="${GITHUB_BRANCH:-main}"
FLUX_PATH="${FLUX_PATH:-./k8s/clusters/home}"
GITHUB_TOKEN_SOPS="${FLUX_REPO}/.secrets/github-pat.sops.yaml"

# Verify sops-age secret exists
if ! kubectl -n "$FLUX_NAMESPACE" get secret sops-age >/dev/null 2>&1; then
    echo "ERROR: sops-age secret not found. Run: make k3s-flux-init"
    exit 1
fi

# Get GitHub token
TOKEN=""
if [[ -f "$GITHUB_TOKEN_SOPS" ]]; then
    echo "[flux-bootstrap] Decrypting GitHub token from $GITHUB_TOKEN_SOPS"
    TOKEN=$(SOPS_AGE_KEY_FILE="$AGE_KEY" sops -d --extract '["github_token"]' "$GITHUB_TOKEN_SOPS" 2>/dev/null || true)
fi

if [[ -z "$TOKEN" ]] && [[ -n "${GITHUB_TOKEN:-}" ]]; then
    TOKEN="$GITHUB_TOKEN"
fi

if [[ -z "$TOKEN" ]]; then
    echo "ERROR: No GitHub token found"
    echo "Either set GITHUB_TOKEN env var or create encrypted token at:"
    echo "  $GITHUB_TOKEN_SOPS"
    exit 1
fi

echo "[flux-bootstrap] Bootstrapping Flux"
GITHUB_TOKEN="$TOKEN" flux bootstrap github \
    --owner="$GITHUB_OWNER" \
    --repository="$GITHUB_REPO" \
    --branch="$GITHUB_BRANCH" \
    --path="$FLUX_PATH" \
    --personal \
    --token-auth

echo "[flux-bootstrap] Configuring SOPS decryption"
kubectl patch kustomization flux-system -n "$FLUX_NAMESPACE" \
    --type merge -p '{"spec":{"decryption":{"provider":"sops","secretRef":{"name":"sops-age"}}}}'

echo "[flux-bootstrap] Reconciling"
flux reconcile kustomization flux-system --with-source

echo "[flux-bootstrap] Done"
