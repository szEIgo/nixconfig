#!/usr/bin/env bash
set -euo pipefail

# Check k3s cluster status

export KUBECONFIG="${KUBECONFIG:-$HOME/.kube/config}"

echo "=== K3s Service ==="
systemctl status k3s --no-pager -l 2>/dev/null | head -15 || echo "k3s service not running"

echo ""
echo "=== Nodes ==="
kubectl get nodes -o wide 2>/dev/null || echo "Cannot connect to cluster"

echo ""
echo "=== Pods (all namespaces) ==="
kubectl get pods -A 2>/dev/null || echo "Cannot get pods"
