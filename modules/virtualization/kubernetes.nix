{ config, pkgs, ... }:

{
  # ... other configuration ...

  services.kubernetes = {
    enable = true;
    package = pkgs.kubernetes_1_33; 
    masterAddress = "127.0.0.1";
    apiserverAddress = "https://127.0.0.1:6443";

    nodes.main = {
      kubelet.extraOpts = "--node-ip=127.0.0.1";
    };
  };

}