{ lib, ... }: {
  # This file was populated at runtime with the networking
  # details gathered from the active system.
  networking = {
    nameservers = [ "8.8.8.8"
 ];
    defaultGateway = "64.225.16.1";
    defaultGateway6 = {
      address = "";
      interface = "eth0";
    };
    dhcpcd.enable = false;
    usePredictableInterfaceNames = lib.mkForce false;
    interfaces = {
      eth0 = {
        ipv4.addresses = [
          { address="64.225.24.98"; prefixLength=20; }
{ address="10.17.0.5"; prefixLength=16; }
        ];
        # ipv6.addresses = [
        #   { address="fe80::e01c:21ff:fe13:8cf8"; prefixLength=64; }
        # ];
        ipv4.routes = [ { address = "64.225.16.1"; prefixLength = 32; } ];
        # ipv6.routes = [ { address = ""; prefixLength = 128; } ];
      };
      
    };
  };
  services.udev.extraRules = ''
    ATTR{address}=="e2:1c:21:13:8c:f8", NAME="eth0"
    ATTR{address}=="0a:39:97:87:ac:a3", NAME="eth1"
  '';
}