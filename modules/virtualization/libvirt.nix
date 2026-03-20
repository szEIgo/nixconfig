{ pkgs, ... }:

{
  users.groups = { libvirtd = { }; };

  # Allow libvirtd group members to manage VMs without sudo
  security.polkit.extraConfig = ''
    polkit.addRule(function(action, subject) {
      if (action.id == "org.libvirt.unix.manage" &&
          subject.isInGroup("libvirtd")) {
        return polkit.Result.YES;
      }
    });
  '';

  virtualisation.libvirtd = {
    enable = true;

    qemu = {
      package = pkgs.qemu_kvm;
      runAsRoot = true;
      swtpm.enable = true;
    };
  };

  systemd.tmpfiles.rules = [ "z /dev/zd* 0660 root libvirtd -" ];

  systemd.services.libvirtd.serviceConfig = {
    SupplementaryGroups = [ "libvirtd" ];
  };

  # Transparent Huge Pages in madvise mode - QEMU uses madvise() to request
  # huge pages without pre-allocating memory like static hugepages
  boot.kernelParams = [ "transparent_hugepage=madvise" ];

  # KSM (Kernel Same-page Merging) - deduplicates identical memory pages across VMs
  # Useful when running multiple similar Windows VMs
  hardware.ksm = {
    enable = true;
    sleep = 200;  # ms between scans (default is 20, 200 = less CPU overhead)
  };
}

