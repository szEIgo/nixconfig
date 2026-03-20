#!/usr/bin/env bash
set -euo pipefail

# Check Flux CD status

export KUBECONFIG="${KUBECONFIG:-$HOME/.kube/config}"

echo "=== Flux Controllers ==="
kubectl get pods -n flux-system 2>/dev/null || echo "Flux not installed"

echo ""
echo "=== Git Repositories ==="
flux get sources git -A 2>/dev/null || true

echo ""
echo "=== Helm Repositories ==="
flux get sources helm -A 2>/dev/null || true

echo ""
echo "=== Kustomizations ==="
flux get kustomizations -A 2>/dev/null || true

echo ""
echo "=== Helm Releases ==="
flux get helmreleases -A 2>/dev/null || true
