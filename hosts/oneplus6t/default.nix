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
  # Provision joni user
  home.activation.provisionJoniUser = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if ! /usr/bin/grep -q "^joni:" /etc/passwd; then
      ${doas} /usr/sbin/adduser -D -s /bin/sh joni
      ${doas} /usr/sbin/addgroup joni wheel 2>/dev/null || true
    fi

    # Ensure joni account is unlocked (sshd rejects locked accounts)
    # Set a disabled-login password marker (! prefix means no password login, but account is active)
    ${doas} /usr/sbin/usermod -p '*' joni 2>/dev/null || true

    # Fix home directory permissions (sshd is strict about group-writable)
    ${doas} /usr/bin/chmod 755 /home/joni
    ${doas} /usr/bin/chmod g-s /home/joni

    # Deploy authorized_keys for joni (clear setgid inherited from parent)
    ${doas} /usr/bin/mkdir -p /home/joni/.ssh
    ${doas} /usr/bin/chmod 0700 /home/joni/.ssh
    ${doas} /usr/bin/chmod g-s /home/joni/.ssh
    echo '${authorizedKeysText}' | ${doas} /usr/bin/tee /home/joni/.ssh/authorized_keys > /dev/null
    ${doas} /usr/bin/chmod 600 /home/joni/.ssh/authorized_keys
    ${doas} /usr/bin/chown -R joni:joni /home/joni/.ssh
  '';

  # Provision authorized_keys for the default user too
  home.file.".ssh/authorized_keys" = {
    text = authorizedKeysText;
  };

  # Configure sshd declaratively
  home.activation.configureSshd = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    echo '${sshdConfig}' | ${doas} /usr/bin/tee /etc/ssh/sshd_config > /dev/null
    ${doas} /sbin/rc-service sshd restart 2>/dev/null || true
    ${doas} /sbin/rc-update add sshd default 2>/dev/null || true
  '';

  # Configure doas to allow wheel group
  home.activation.configureDoas = lib.hm.dag.entryAfter [ "provisionJoniUser" ] ''
    if ! ${doas} /usr/bin/grep -q "permit persist :wheel" /etc/doas.d/doas.conf 2>/dev/null; then
      echo 'permit persist :wheel' | ${doas} /usr/bin/tee -a /etc/doas.d/doas.conf > /dev/null
    fi
  '';
}
