{ config, lib, pkgs, ... }: {
  imports = [
    # General, non-graphics modules
    ./packages.nix
    ./devices/wireguard-server.nix
    ../../modules/common/locales.nix
    ../../modules/common/users.nix
    ../../modules/common/zsh.nix
    ../../modules/common/zfs.nix
    ../../modules/virtualization/libvirt.nix
    ../../modules/virtualization/podman.nix
    ../../modules/virtualization/k3s.nix
    ../../remote/ssh.nix
  ];
  boot.extraModulePackages = [ config.boot.kernelPackages.vendor-reset ];
  boot.kernelModules = [
    "kvm-amd"
    "vfio"
    "vfio_iommu_type1"
    "vfio_pci"
    "vfio_virqfd"
    "dm-crypt"
    "vendor-reset"
    "wireguard"
  ];

  boot.kernelParams = [
    "amd_iommu=on"
    "iommu=pt"
    "pcie_acs_override=downstream,multifunction"
    "rd.driver.pre=vfio-pci"
    # Bind BOTH GPUs to vfio-pci by default
    "vfio-pci.ids=10de:1f07,10de:10f9,10de:1ada,10de:1adb,1002:ab38,1002:731f,10ec:8125"
    "video=efifb:off"
    "modprobe.blacklist=nouveau"
    "rd.driver.blacklist=nouveau"
    "amdgpu.runpm=0"
    "amdgpu.aspm=0"
  ];

  boot.blacklistedKernelModules = [ "nouveau" "nvidia" "amdgpu" "nvidia_drm" "nvidia_modeset" ];
  boot.initrd.kernelModules = [
    "dm-snapshot"
  ];

  services.xserver = lib.mkDefault {
    enable = false;
  };

  # Prevent the kernel from auto-loading host USB drivers (xhci/nouveau)
  # for specific NVIDIA devices so vfio can bind them in userspace.
  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{device}=="0x1ada", \
    ATTR{driver_override}="vfio-pci"
  '';


  hardware.graphics = lib.mkDefault {
    enable = false;
    enable32Bit = false;
    extraPackages = [];
  };

  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.configurationLimit = 10;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.supportedFilesystems = [ "zfs" "ntfs" ];
  boot.zfs.requestEncryptionCredentials = true;
  boot.initrd.luks.devices."cryptroot".device =
    "/dev/disk/by-uuid/2191f348-040d-42e3-9caf-c43b86f9a6df";

  # Xanmod kernel includes ACS override patch for IOMMU group separation
  boot.kernelPackages = pkgs.linuxPackages_xanmod;
  hardware.nvidia.package = config.boot.kernelPackages.nvidiaPackages.stable;
  boot.crashDump.enable = true;
  boot.kernel.sysctl."kernel.watchdog" = 1;

  networking.hostName = "mothership";
  networking.hostId = "6d539f2f";

  users.defaultUserShell = pkgs.zsh;
  virtualisation.containers.enable = true;

  environment.sessionVariables = {
    XDG_CACHE_HOME = "$HOME/.cache";
    XDG_CONFIG_HOME = "$HOME/.config";
    XDG_DATA_HOME = "$HOME/.local/share";
    XDG_STATE_HOME = "$HOME/.local/state";
  };

  # Required when Home Manager is installed via NixOS module with useUserPackages
  environment.pathsToLink = [ "/share/applications" "/share/xdg-desktop-portal" ];

  zramSwap.enable = true;
  zramSwap.algorithm = "zstd";
  security.polkit.enable = true;

  # Provide the dconf D-Bus service required by Home Manager's dconf module
  services.dbus.enable = true;
  services.dbus.packages = [ pkgs.dconf ];
  programs.dconf.enable = true;

  specialisation = {
    dualGpu.configuration = {
      system.nixos.tags = [ "dualGpu" "desktop" ];
      imports = [
        ../../modules/desktop/hyprland.nix
        ../../modules/desktop/plasma.nix
        ../../modules/common/services.nix
        ./devices/dualGpu.nix
        ./devices/sunshine.nix
      ];
    };

    amd.configuration = {
      system.nixos.tags = [ "amd" "vfio" "desktop" ];
      imports = [
        ./devices/amd.nix
        ../../modules/desktop/hyprland.nix
        ../../modules/desktop/plasma.nix
        ../../modules/common/services.nix
        ./devices/sunshine.nix
        ../../modules/gaming/steam.nix
      ];
    };

    nvidia.configuration = {
      system.nixos.tags = [ "nvidia" "vfio" "desktop" ];
      imports = [
        ./devices/nvidia.nix
        ../../modules/desktop/hyprland.nix
        ../../modules/desktop/plasma.nix
        ../../modules/common/services.nix
      ];
    };
  };

  system.stateVersion = "25.11";
}
