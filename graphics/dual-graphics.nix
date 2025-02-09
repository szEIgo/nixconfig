{ config, lib, pkgs, ... }:
{
  boot.kernelModules = ["kvm-amd" ];
  boot.kernelParams = [ "amd_iommu=on" "iommu=pt" "amdgpu.runpm=0" ];
  boot.blacklistedKernelModules = [ "vfio" "nouveau" ];

  boot.initrd.kernelModules = [ "dm-snapshot" "amdgpu"];

  hardware.graphics.extraPackages = with pkgs; [
    amdvlk
  ];


  hardware.nvidia = {
    open = true;
    modesetting.enable = true;
    powerManagement.enable = false;
    powerManagement.finegrained = false;
    package = config.boot.kernelPackages.nvidiaPackages.mkDriver {
      version = "570.86.16"; # use new 570 drivers
      sha256_64bit = "sha256-RWPqS7ZUJH9JEAWlfHLGdqrNlavhaR1xMyzs8lJhy9U=";
      openSha256 = "sha256-DuVNA63+pJ8IB7Tw2gM4HbwlOh1bcDg2AN2mbEU9VPE=";
      settingsSha256 = "sha256-9rtqh64TyhDF5fFAYiWl3oDHzKJqyOW3abpcf2iNRT8=";
      usePersistenced = false;
    };

  };
  services = {
    xserver = {
        enable = true;
        #videoDrivers = ["nvidia"];
        videoDrivers = ["amdgpu"];
        deviceSection = ''
              Option "TearFree" "true"
            '';
    };
  };


}
