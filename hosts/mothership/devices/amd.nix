{
  config,
  lib,
  pkgs,
  ...
}: {
  boot.kernelModules = ["kvm-amd" "vfio" "vfio_iommu_type1" "vfio_pci" "vfio_virqfd" "dm-crypt"];
  boot.kernelParams = ["amd_iommu=on" "iommu=pt" "amdgpu.runpm=0" "vfio-pci.ids=10de:1f07,10de:10f9,10de:1ada,10de:1adb,"];
  boot.blacklistedKernelModules = ["nouveau" "nvidia"];

  boot.initrd.kernelModules = ["dm-snapshot" "amdgpu"];

  hardware.graphics.extraPackages = with pkgs; [
    amdvlk
  ];

  services = {
    xserver = {
      enable = true;
      videoDrivers = ["amdgpu"];
      deviceSection = ''
        Option "TearFree" "true"
      '';
    };
  };
}
