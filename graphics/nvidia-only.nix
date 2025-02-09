{ config, lib, pkgs, ... }:
{
  boot.kernelModules = ["kvm-amd" "vfio" "vfio_iommu_type1" "vfio_pci" "vfio_virqfd" ];
  boot.kernelParams = [ "amd_iommu=on" "iommu=pt" "vfio-pci.ids=1002:ab38,1002:731f" ];
  boot.blacklistedKernelModules = [ "amdgpu" "amd"];

  boot.initrd.kernelModules = [ "dm-snapshot" "nvidia" ];
  hardware.graphics.extraPackages = with pkgs; [];
  hardware.nvidia = {
    open = true;
    modesetting.enable = true;
    powerManagement.enable = false;
    powerManagement.finegrained = false;
    #package = config.boot.kernelPackages.nvidiaPackages.beta;
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
        videoDrivers = ["nvidia"];
    };
  };


}
