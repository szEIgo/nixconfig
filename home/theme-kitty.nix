{ config, lib, pkgs, ... }:
{
  programs.kitty = {
    enable = true;
    font = {
      name = "JetBrainsMono Nerd Font";
      size = 11;
    };
    themeFile = "OneHalfDark";
    settings = {
      enable_audio_bell = false;
      background_opacity = "0.95";
      cursor_shape = "beam";
    };
  };
}
