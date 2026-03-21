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
      "--node-ip=192.168.2.211"
    ];
  };

  # Container runtime
  virtualisation.containerd.enable = true;

  # Firewall - allow kubelet and flannel
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

  # Minimal packages for a worker node
  environment.systemPackages = with pkgs; [
    curl
    htop
    iproute2
    vim
  ];

  system.stateVersion = "25.11";
}
