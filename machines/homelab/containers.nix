{ config, ... }:
let
  haIp = config.tw.containers.home-assistant.containerIp;
in
{
  tw.containers.actual-budget.enable = true;
  tw.containers.lemmy.enable = true;
  tw.containers.matrix.enable = true;
  tw.containers.obsidian-sync.enable = true;
  tw.containers.vaultwarden.enable = true;
  tw.containers.home-assistant.enable = true;
  tw.containers.airplane.enable = true;

  networking = {
    nat = {
      enable = true;
      internalInterfaces = [ "ve-+" ];
      externalInterface = "eno1";
    };

    firewall = {
      enable = true;
      checkReversePath = "strict";
      # Prevent containers from accessing the host, each other, or the local network
      extraCommands = ''
        # 1. Host INPUT: containers never need to initiate connections to the homelab host
        iptables -N containers-input 2>/dev/null || iptables -F containers-input
        iptables -C INPUT -i ve-+ -j containers-input 2>/dev/null || iptables -I INPUT -i ve-+ -j containers-input
        iptables -A containers-input -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
        iptables -A containers-input -j DROP

        # 2. Routed FORWARD: isolate containers from each other and the home LAN
        blockIpv4() {
          iptables -A containers-forward -d "$@" -j DROP
        }
        iptables -N containers-forward 2>/dev/null || iptables -F containers-forward
        iptables -C FORWARD -i ve-+ -j containers-forward 2>/dev/null || iptables -I FORWARD -i ve-+ -j containers-forward
        iptables -A containers-forward -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

        # Prevent containers from forwarding traffic directly to other containers
        iptables -A containers-forward -o ve-+ -j DROP

        # Exception: Allow Home Assistant to query the router DNS (192.168.1.1) for local hostnames
        iptables -A containers-forward -s ${haIp} -d 192.168.1.1 -p udp --dport 53 -j ACCEPT
        iptables -A containers-forward -s ${haIp} -d 192.168.1.1 -p tcp --dport 53 -j ACCEPT

        # Exception: Allow Home Assistant to reach wireless devices and MQTT broker on the isolated 192.168.55.0/24 VLAN
        iptables -A containers-forward -s ${haIp} -d 192.168.55.0/24 -j ACCEPT

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

        # 3. IPv6: Drop all IPv6 from container veth interfaces (containers only use IPv4)
        ip6tables -N containers-v6 2>/dev/null || ip6tables -F containers-v6
        ip6tables -C INPUT -i ve-+ -j containers-v6 2>/dev/null || ip6tables -I INPUT -i ve-+ -j containers-v6
        ip6tables -C FORWARD -i ve-+ -j containers-v6 2>/dev/null || ip6tables -I FORWARD -i ve-+ -j containers-v6
        ip6tables -A containers-v6 -j DROP
      '';
    };
  };
}
