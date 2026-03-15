{ config, lib, pkgs, ... }:
let
  androidComposition = pkgs.androidenv.composeAndroidPackages {
    cmdLineToolsVersion = "11.0";
    platformToolsVersion = "35.0.1";
    buildToolsVersions = [ "34.0.0" "35.0.0" ];
    platformVersions = [ "34" "35" "36" ];
    abiVersions = [ "arm64-v8a" "x86_64" ];
    includeEmulator = false;
    includeNDK = true;
    ndkVersions = [ "27.0.12077973" ];
    cmakeVersions = [ "3.22.1" ];
  };
in {
  imports = [ ../../modules/common/packages.nix ];

  environment.systemPackages = with pkgs; [
    openvscode-server
    virt-manager
    qemu
    libvirt
    xorg.xauth
    amdgpu_top
    kdePackages.yakuake
    kdePackages.kdeconnect-kde
    xwayland-satellite
    kmod
    zfs
    cryptsetup
    moonlight-qt
    podman
    podman-tui
    podman-compose
    dive
    yazi
    zellij
    k9s
    wayvnc
    tigervnc
    # Flutter/Android development
    flutter
    jdk17
    androidComposition.androidsdk
  ];

  # Set Android SDK environment
  environment.variables = {
    ANDROID_HOME = "${androidComposition.androidsdk}/libexec/android-sdk";
    ANDROID_SDK_ROOT = "${androidComposition.androidsdk}/libexec/android-sdk";
  };
  networking.firewall.allowedTCPPorts = [ 5900 ];

  programs = {
    partition-manager.enable = true;
    xwayland.enable = true;
    kdeconnect.enable = true;
    nix-ld = {
      enable = true;
      libraries = with pkgs; [
        stdenv.cc.cc
        zlib
        fuse3
        icu
        nss
        openssl
        curl
        expat
      ];
    };

    gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
      settings = {
        default-cache-ttl = 1800;
        max-cache-ttl = 7200;
      };
      pinentryPackage = pkgs.pinentry-tty;
    };
  };
}
