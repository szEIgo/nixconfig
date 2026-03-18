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

  # systemd-oomd: userspace OOM killer - configured as last resort only
  #  systemd.oomd = {
  #    enable = true;
  #    enableRootSlice = true;
  #    enableSystemSlice = true;
  #    enableUserSlices = true;
  #    extraConfig = {
  # Only trigger when swap is nearly exhausted (default: 90%)
  #      SwapUsedLimit = "95%";
  #      # Only trigger at very high memory pressure (default: 60%)
  #      DefaultMemoryPressureLimit = "90%";
  #      # Wait longer before killing - gives system time to recover (default: 30s)
  #      DefaultMemoryPressureDurationSec = "120s";
  #   };
  # };

  # Memory management and OOM killer tuning
  boot.kernel.sysctl = {
    # Swap/memory pressure
    "vm.swappiness" = 60; # Use swap more (default: 60, was 10)
    "vm.vfs_cache_pressure" = 50; # Less aggressive cache reclaim (default: 100)

    # Overcommit control - prevent over-allocation
    "vm.overcommit_memory" = 0; # Heuristic overcommit (was 1 = always allow)
    "vm.overcommit_ratio" = 80; # Allow 80% RAM + swap when overcommit_memory=2

    # Kernel OOM killer behavior
    "vm.oom_kill_allocating_task" = 0; # Kill highest score process, not requester
    "vm.panic_on_oom" = 0; # Don't kernel panic, just kill
    "vm.min_free_kbytes" = 131072; # Keep 128MB emergency reserve (default: ~67MB)
  };
}

