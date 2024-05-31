{...}:{
  sops = {
    defaultSopsFile = ./secrets.yaml;
    age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
    secrets = {
      "cloudflare/tunnels/homelab.json" = {};
      "cloudflare/tunnels/lemmy.json" = {};
      "cloudflare/tunnels/matrix.json" = {};
      "cloudflare/tunnels/vaultwarden.json" = {};
      "matrix/sharedSecret" = {};
    };
  };
}