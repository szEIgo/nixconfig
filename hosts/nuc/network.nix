# Network configuration for the Intel NUC
#
# Uses DHCP for now. Once the interface name is known (check `ip link`),
# this can be switched to a static IP.
{
  networking.useDHCP = true;

  services.resolved = {
    enable = true;
    settings = {
      Resolve = {
        DNSStubListener = "no";
      };
    };
  };
}
