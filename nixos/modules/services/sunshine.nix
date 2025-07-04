# ./nixos/modules/services/sunshine.nix
{ ... }: {
  services.sunshine = {
    enable = true;
    openFirewall = true;
    capSysAdmin = true;
  };
}
