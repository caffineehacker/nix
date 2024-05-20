{...}:{
  sops = {
    defaultSopsFile = ./secrets.yaml;
    age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
    secrets = {
      "cloudflare/tunnels/homelab.json" = {};
    };
  };
}