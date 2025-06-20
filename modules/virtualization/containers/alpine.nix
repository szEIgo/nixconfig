{ pkgs ? import <nixpkgs> { } }:

pkgs.dockerTools.buildImage {
  name = "my-nix-image";
  tag = "latest";
  contents = [ pkgs.curl pkgs.bash ];
  config = { Cmd = [ "bash" ]; };
}
