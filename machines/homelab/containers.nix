{ ... }: {
  tw.containers.lemmy.enable = true;
  tw.containers.matrix.enable = true;
  tw.containers.obsidian-sync.enable = true;
  tw.containers.vaultwarden.enable = true;

  networking = {
    nat = {
      enable = true;
      internalInterfaces = [ "ve-+" ];
      externalInterface = "eno1";
    };

    firewall = {
      enable = true;
      # Prevent containers from accessing the local network
      extraCommands = ''
        blockIpv4() {
          iptables -A containers -i ve-+ -d "$@" -j DROP
        }
        iptables -N containers || iptables -F containers
        iptables -C INPUT -i ve-+ -j containers || iptables -I INPUT -i ve-+ -j containers
        iptables -A containers -i ve-+ -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
        blockIpv4 0.0.0.0/8
        blockIpv4 10.0.0.0/8
        blockIpv4 100.64.0.0/10
        blockIpv4 127.0.0.0/8
        blockIpv4 169.254.0.0/16
        blockIpv4 172.16.0.0/12
        blockIpv4 192.0.0.0/24
        blockIpv4 192.0.2.0/24
        blockIpv4 192.168.0.0/16
        blockIpv4 192.88.99.0/24
        blockIpv4 198.18.0.0/15
        blockIpv4 198.51.100.0/24
        blockIpv4 203.0.113.0/24
        blockIpv4 224.0.0.0/4
        blockIpv4 233.252.0.0/24
        blockIpv4 240.0.0.0/4
        blockIpv4 255.255.255.255/32

        blockIpv6() {
          ip6tables -A containers -i ve-+ -d "$@" -j DROP
        }
        ip6tables -N containers || ip6tables -F containers
        ip6tables -C INPUT -i ve-+ -j containers || ip6tables -I INPUT -i ve-+ -j containers
        ip6tables -A containers -i ve-+ -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
        blockIpv6 ::/128
        blockIpv6 ::1/128
        blockIpv6 64:ff9b:1::/48
        blockIpv6 fc00::/7
        blockIpv6 fe80::/10
        blockIpv6 fec0::/10
        blockIpv6 ff00::/8
      '';
    };
  };
}
