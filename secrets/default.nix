{config, ...}:{
  sops = {
    defaultSopsFile = ./secrets.yaml;
    age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
    secrets = {
      "cloudflare/tunnels/homelab.json" = {};
      "cloudflare/tunnels/lemmy.json" = {};
      "cloudflare/tunnels/matrix.json" = {};
      "cloudflare/tunnels/vaultwarden.json" = {};
      "matrix/sharedSecret" = {};
      "matrix/wireguard/clientKey" = {};
      "matrix/wireguard/serverKey" = {
        owner = config.users.users.systemd-network.name;
        group = config.users.groups.systemd-network.name;
        mode = "0640";
        reloadUnits = [ "systemd-networkd.service" ];
      };
    };
  };
}