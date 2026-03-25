# PostmarketOS system provisioning for OnePlus 6T
# Since postmarketOS is Alpine-based (not NixOS), we use home-manager
# activation scripts to declaratively manage system-level config via doas.
{ config, lib, pkgs, ... }:

let
  authorizedKeysFile = ../../remote/authorized_keys;
  authorizedKeys = lib.lists.filter (key: key != "") (
    lib.strings.splitString "\n" (builtins.readFile authorizedKeysFile)
  );
  authorizedKeysText = lib.concatStringsSep "\n" authorizedKeys;

  doas = "/usr/bin/doas";

  sshdConfig = ''
    Port 22
    ListenAddress 0.0.0.0
    PermitRootLogin prohibit-password
    PasswordAuthentication no
    PubkeyAuthentication yes
    AuthorizedKeysFile %h/.ssh/authorized_keys
    X11Forwarding no
    Subsystem sftp /usr/lib/ssh/sftp-server
    MACs hmac-sha2-512,hmac-sha2-256,hmac-sha1
  '';
in {
  # Deploy authorized_keys for the user account
  home.file.".ssh/authorized_keys" = {
    text = authorizedKeysText;
  };

  # Configure sshd declaratively
  home.activation.configureSshd = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    echo '${sshdConfig}' | ${doas} /usr/bin/tee /etc/ssh/sshd_config > /dev/null
    ${doas} /sbin/rc-service sshd restart 2>/dev/null || true
    ${doas} /sbin/rc-update add sshd default 2>/dev/null || true
  '';
}
