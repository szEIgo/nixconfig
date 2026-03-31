{ config, lib, pkgs, ... }:

let
  cfg = config.local.ssh;

  authorizedKeysFile = ./authorized_keys;

  authorizedKeys = lib.lists.filter (key: key != "") (
    lib.strings.splitString "
" (builtins.readFile authorizedKeysFile)
  );

in {
  options.local.ssh = {
    desktop = lib.mkEnableOption "desktop SSH settings (GTK pinentry)";
    passwordAuth = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Allow password authentication (disable after SSH key auth is verified)";
    };
  };

  config = {
    programs = {
      ssh = {
        forwardX11 = true;
        setXAuthLocation = true;
      };
      gnupg.agent = {
        enable = true;
        enableSSHSupport = true;
        settings = {
          default-cache-ttl = 28800;
          max-cache-ttl = 28800;
          default-cache-ttl-ssh = 28800;
          max-cache-ttl-ssh = 28800;
        };
        pinentryPackage = if cfg.desktop then pkgs.pinentry-gnome3 else pkgs.pinentry-curses;
      };
    };

    # SSH askpass for desktop (prompts for SSH key passphrases via GUI)
    environment.systemPackages = lib.mkIf cfg.desktop [ pkgs.kdePackages.ksshaskpass ];
    environment.variables = lib.mkIf cfg.desktop {
      SSH_ASKPASS = lib.mkForce "${pkgs.kdePackages.ksshaskpass}/bin/ksshaskpass";
      SSH_ASKPASS_REQUIRE = "prefer";
    };

    services.openssh = {
      enable = true;
      listenAddresses = [{
        addr = "0.0.0.0";
        port = 22;
      }];
      settings = {
        PermitRootLogin = "prohibit-password";
        PasswordAuthentication = cfg.passwordAuth;
        X11Forwarding = true;
        Macs = [ "hmac-sha2-512" "hmac-sha2-256" "hmac-sha1" ];
      };
    };

    users.users = {
      joni.openssh.authorizedKeys.keys = authorizedKeys;
      root.openssh.authorizedKeys.keys = authorizedKeys;
    };
  };
}
