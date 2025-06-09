{
  config,
  lib,
  pkgs,
  ...
}: {
  boot.kernelModules = ["kvm-amd" "vfio" "vfio_iommu_type1" "vfio_pci" "vfio_virqfd"];
  boot.kernelParams = ["amd_iommu=on" "iommu=pt" "amdgpu.runpm=0" "vfio-pci.ids=10de:1f07,10de:10f9,10de:1ada,10de:1adb,1002:ab38,1002:731f"];
  boot.blacklistedKernelModules = ["nouveau" "nvidia" "amdgpu"];

  boot.initrd.kernelModules = ["dm-snapshot"];
}
