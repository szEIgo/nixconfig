{
  config,
  lib,
  pkgs,
  ...
}: {
  boot.kernelModules = ["kvm-amd" "vfio" "vfio_iommu_type1" "vfio_pci" "vfio_virqfd"];
  boot.kernelParams = ["amd_iommu=on" "iommu=pt" "vfio-pci.ids=1002:ab38,1002:731f"];
  boot.blacklistedKernelModules = ["amdgpu" "amd"];

  boot.initrd.kernelModules = ["dm-snapshot" "nvidia"];
  hardware.graphics.extraPackages = with pkgs; [];
  hardware.nvidia = {
    package = config.boot.kernelPackages.nvidiaPackages.latest;
    open = true;
    #enabled = true;
    modesetting.enable = true;
  };

  services = {
    xserver = {
      enable = true;
      videoDrivers = ["nvidia"];
    };
  };
}
