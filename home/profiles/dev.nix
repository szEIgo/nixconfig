# Dev profile: Development tools for workstations
# Include this on machines where you do development work
{ config, lib, pkgs, ... }:

{
  home.packages = with pkgs; [
    # Kubernetes
    kubectl
    k9s
    kustomize
    fluxcd

    # Container tools
    dive

    # Languages & runtimes
    rustc
    cargo
    rustfmt
    sbt
    scala
    temurin-bin-25

    # Python
    python312
    uv
    ruff
    basedpyright
    python312Packages.ipython
    
    # Build tools
    gnumake

    # Cloud & infrastructure
    sops
    age
    wireguard-tools

    # Documentation
    plantuml
    graphviz
  ];
}
