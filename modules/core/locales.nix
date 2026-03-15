# Locale settings: timezone, language, keyboard
{ config, lib, pkgs, ... }:

{
  time.timeZone = lib.mkDefault "Europe/Copenhagen";
  i18n.defaultLocale = lib.mkDefault "en_US.UTF-8";

  console = {
    keyMap = lib.mkDefault "dk";
    useXkbConfig = true;
  };
}
