{
  config,
  lib,
  pkgs,
  ...
}: {
  users.users.joni = {
    isNormalUser = true;
    extraGroups = ["wheel" "libvirtd" "podman"];
    shell = pkgs.zsh;
  };

  users.defaultUserShell = pkgs.zsh;
}
