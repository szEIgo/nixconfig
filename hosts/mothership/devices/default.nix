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
    #modesetting.enable = true;
    package = config.boot.kernelPackages.nvidiaPackages.latest;
    open = true;
    powerManagement.enable = false;
    powerManagement.finegrained = false;
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
