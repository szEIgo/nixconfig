{ config, lib, pkgs, ... }: {
  imports = [
    # Shared modules
    ../../modules/common/zsh.nix

    # Remote access
    ../../remote/ssh.nix
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.configurationLimit = 10;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "nuc";

  users.defaultUserShell = pkgs.zsh;

  # Required when Home Manager is installed via NixOS module with useUserPackages
  environment.pathsToLink = [ "/share/applications" "/share/xdg-desktop-portal" ];

  environment.sessionVariables = {
    EDITOR = "vim";
    KUBECONFIG = "/etc/rancher/k3s/k3s.yaml";
  };

  # k3s agent joining the mothership server
  services.k3s = {
    enable = true;
    role = "agent";
    serverAddr = "https://192.168.2.62:6443";
    tokenFile = "/etc/k3s/token";
    extraFlags = [
      "--node-label=k3s.io/role=worker"
      "--node-label=node-role=customer"
      "--node-label=node-type=bare-metal"
      "--node-label=node-id=nuc"
    ];
  };

  # Firewall
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [
      22    # SSH
      10250 # kubelet
    ];
    allowedUDPPorts = [
      8472 # flannel VXLAN
    ];
  };

  # Memory management
  zramSwap.enable = true;
  zramSwap.algorithm = "zstd";

  # Ignore power/lid events (headless server)
  services.logind.settings.Login = {
    HandlePowerKey = "ignore";
    HandleLidSwitch = "ignore";
    HandleLidSwitchExternalPower = "ignore";
    IdleAction = "ignore";
  };

  # NFS client support for democratic-csi storage
  boot.supportedFilesystems = [ "nfs" ];

  # Minimal packages for a worker node
  environment.systemPackages = with pkgs; [
    curl
    htop
    iproute2
    vim
    nfs-utils
  ];

  system.stateVersion = "25.11";
}
