#!/usr/bin/env bash
set -euo pipefail

# Force reconcile all Flux resources

export KUBECONFIG="${KUBECONFIG:-$HOME/.kube/config}"

TARGET="${1:-all}"

case "$TARGET" in
    all)
        echo "[flux-reconcile] Reconciling all sources and kustomizations"
        flux reconcile source git flux-system -n flux-system
        flux reconcile kustomization flux-system -n flux-system --with-source
        ;;
    source|sources)
        echo "[flux-reconcile] Reconciling git source"
        flux reconcile source git flux-system -n flux-system
        ;;
    *)
        echo "[flux-reconcile] Reconciling kustomization: $TARGET"
        flux reconcile kustomization "$TARGET" -n flux-system --with-source
        ;;
esac

echo "[flux-reconcile] Done"
