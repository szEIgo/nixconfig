{
  config,
  lib,
  pkgs,
  ...
}: {
  users.users.joni = {
    isNormalUser = true;
    extraGroups = ["wheel" "libvirtd"];
    shell = pkgs.zsh;
  };

  users.defaultUserShell = pkgs.zsh;
}
