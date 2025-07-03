{ config, lib, pkgs, ... }: {
  imports = [
    # General, non-graphics modules
    ./packages.nix
    ./devices/wireguard-server.nix
    ../../modules/common/locales.nix
    ../../modules/common/users.nix
    ../../modules/common/zfs.nix
    ../../modules/virtualization/libvirt.nix
    ../../modules/virtualization/podman.nix
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
    # Bind BOTH GPUs to vfio-pci by default
    "vfio-pci.ids=10de:1f07,10de:10f9,10de:1ada,10de:1adb,1002:ab38,1002:731f,10ec:8125"
    "video=efifb:off"
    "amdgpu.aspm=0"
  ];

  boot.blacklistedKernelModules = [ "nouveau" "nvidia" "amdgpu" ];
  boot.initrd.kernelModules = [ "dm-snapshot" ];

  services.xserver.enable = false;

  hardware.graphics = lib.mkDefault {
    enable = false;
    enable32Bit = false;
    extraPackages = [ ];
  };

  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.configurationLimit = 10;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.supportedFilesystems = [ "zfs" "ntfs" ];
  boot.zfs.requestEncryptionCredentials = true;
  boot.initrd.luks.devices."cryptroot".device =
    "/dev/disk/by-uuid/2191f348-040d-42e3-9caf-c43b86f9a6df";

  boot.kernelPackages = pkgs.linuxPackages_6_14;
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

  zramSwap.enable = true;
  zramSwap.algorithm = "zstd";
  security.polkit.enable = true;

  specialisation = {
    dualGpu.configuration = {
      system.nixos.tags = [ "dualGpu" "desktop" ];
      imports = [
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
        ../../modules/desktop/plasma.nix
        ../../modules/common/services.nix
        ./devices/sunshine.nix
        #./devices/dummydisplay.nix
        ./devices/wireguard-server.nix
        ./../modules/gaming/steam.nix

      ];
    };

    nvidia.configuration = {
      system.nixos.tags = [ "nvidia" "vfio" "desktop" ];
      imports = [
        ./devices/nvidia.nix
        ../../modules/desktop/plasma.nix
        ../../modules/common/services.nix
      ];
    };
  };

  system.stateVersion = "25.05";
}
