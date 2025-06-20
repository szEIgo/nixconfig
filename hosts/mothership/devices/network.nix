{
  config,
  lib,
  pkgs,
  ...
}: {

  networking = {
    useDHCP = false;
    interfaces.enp6s0 = {
      useDHCP = true;
      ipv4.addresses = [
        {
          address = "192.168.2.62";
          prefixLength = 24;
        }
      ];
    };

    #interfaces.enp7s0 = {
    #  useDHCP = false;
    #  ipv4.addresses = [
    #    {
    #      address = "192.168.2.63";
    #      prefixLength = 24;
    #    }
    #  ];
    #};

    defaultGateway = {
      address = "192.168.2.1";
      interface = "enp6s0";
    };
    nameservers = ["1.1.1.1" "8.8.8.8"];

  };
}
