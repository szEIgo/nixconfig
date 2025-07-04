# ./home-manager/modules/gui/default.nix
# Packages and settings for graphical environments
{ pkgs, ... }: {
  home.packages = with pkgs; [
    firefox
    vscodium
    copyq # Clipboard manager
  ];

  programs.helix = {
    enable = true;
    settings = {
      theme = "autumn_night";
      editor = {
        cursor-shape = {
          normal = "block";
          insert = "bar";
          select = "underline";
        };
        auto-format = true;
      };
    };
    languages.language = [{
      name = "nix";
      formatter.command = "${pkgs.nixfmt-rfc-style}/bin/nixfmt";
    }];
  };
}
