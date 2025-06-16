{ config, pkgs, ... }:

let
  libvirtGroup = "libvirtd"; 
in {
  users.groups = {
    libvirtd = {};
  };

  users.users.joni = {
    extraGroups = [ libvirtGroup, "kvm" ];
  };

  virtualisation.libvirt = {
    enable = true;

    qemu = {
      package = pkgs.qemu_kvm;
      runAsRoot = true;
      swtpm.enable = true; 

      ovmf = {
        enable = true;
        packages = [
          (pkgs.OVMF.override {
            secureBoot = true;
            tpmSupport = true;
          }).fd
        ];
      };
    };
  };

  systemd.tmpfiles.rules = [
    "z /dev/zd* 0660 root libvirtd -"
  ];

  systemd.services.libvirtd.serviceConfig = {
    SupplementaryGroups = [ libvirtGroup ];
  };
}
