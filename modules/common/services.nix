{ config, lib, pkgs, ... }: {
  services = {
    logind = {
      settings.Login = {
        HandlePowerKey = "ignore";
        HandleLidSwitch = "ignore";
        HandleLidSwitchExternalPower = "ignore";
        IdleAction = "ignore";
      };
    };
    displayManager = {
      sddm.enable = true;
      sddm.wayland.enable = true;
    };
  };

  # Memory management and OOM killer tuning
  boot.kernel.sysctl = {
    "vm.swappiness" = 60;
    "vm.vfs_cache_pressure" = 50;

    # Overcommit control - prevent over-allocation
    "vm.overcommit_memory" = 0;
    "vm.overcommit_ratio" = 80; 

    # Kernel OOM killer behavior
    "vm.oom_kill_allocating_task" = 0;
    "vm.panic_on_oom" = 0;
    "vm.min_free_kbytes" = 131072;
  };
}

