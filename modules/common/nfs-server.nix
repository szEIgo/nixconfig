# NFS server for democratic-csi
# Exports ZFS datasets to k3s worker nodes over the LAN and microvm bridge
{ config, lib, pkgs, ... }: {

  services.nfs.server = {
    enable = true;
    exports = ''
      /fastPool/k3s/nfs  192.168.2.0/24(rw,no_subtree_check,no_root_squash,async) 10.100.0.0/24(rw,no_subtree_check,no_root_squash,async)
      /slowPool/k3s/nfs  192.168.2.0/24(rw,no_subtree_check,no_root_squash,async) 10.100.0.0/24(rw,no_subtree_check,no_root_squash,async)
    '';
  };

  # Open NFS ports for LAN
  networking.firewall.allowedTCPPorts = [ 2049 ];
}
