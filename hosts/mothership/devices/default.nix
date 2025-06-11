{
  config,
  lib,
  pkgs,
  ...
}: {
  boot.kernelModules = ["kvm-amd" "dm-crypt"];
  boot.kernelParams = ["amd_iommu=on" "iommu=pt" "amdgpu.runpm=0" "modprobe.blacklist=nouveau" "rd.driver.blacklist=nouveau" ];
  boot.blacklistedKernelModules = ["vfio" "nouveau"];

  boot.initrd.kernelModules = ["dm-snapshot" "amdgpu"];

  hardware.graphics.extraPackages = with pkgs; [
    amdvlk
  ];

  hardware.nvidia = {
    modesetting.enable = true;
    package = config.boot.kernelPackages.nvidiaPackages.latest;
    open = true;
    powerManagement.enable = false;
    powerManagement.finegrained = false;
  };
  services = {
    xserver = {
      enable = true;  
      videoDrivers = ["amdgpu" "nvidia"];
      deviceSection = ''
        Option "TearFree" "true"
      '';
    };
  };
}
