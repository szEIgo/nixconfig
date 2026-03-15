#!/usr/bin/env bash
set -euo pipefail

# Initialize k3s kubeconfig for current user

mkdir -p ~/.kube
sudo install -D -m 600 -o "$USER" -g "$(id -gn)" /etc/rancher/k3s/k3s.yaml ~/.kube/config
echo "Kubeconfig installed to ~/.kube/config"
