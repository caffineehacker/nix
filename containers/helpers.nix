{ lib, ... }: {
  module = cfg: { ... }: {
    config = lib.mkIf cfg.enable {
      containers."${cfg.name}" = {
        autoStart = true;
        privateNetwork = true;
        hostAddress = cfg.hostIp;
        localAddress = cfg.containerIp;

        extraFlags =
          if cfg.cloudflare.enable then [
            # Load the cloudflare secret
            "--load-credential=tunnel.json:${cfg.cloudflare.tunnelFile}"
          ] else if cfg.wireguard.enable then [
            "--load-credential=network.wireguard.private.10-wg0:${cfg.wireguard.privateKeyFile}"
          ] else [ ];
      };
    };
  };

  containerConfigModule = cfg: { config, pkgs, lib, ... }: {
    system.stateVersion = "23.11";

    imports = [
      ./cloudflared.nix
      ./wireguard.nix
    ];

    tw.containers.cloudflared = lib.mkIf (cfg.cloudflare.enable) {
      enable = true;
      tunnelId = cfg.cloudflare.tunnelId;
      hostname = cfg.hostname;
      port = cfg.cloudflare.port;
    };

    tw.containers.wireguard = lib.mkIf (cfg.wireguard.enable) {
      enable = true;
      port = cfg.wireguard.port;
      tunnelIp = cfg.wireguard.tunnelIp;
    };

    networking = {
      firewall = {
        enable = true;
        allowedTCPPorts = [ ];
      };
      # Use systemd-resolved inside the container
      # Workaround for bug https://github.com/NixOS/nixpkgs/issues/162686
      useHostResolvConf = lib.mkForce false;
    };

    services.resolved.enable = true;

    boot.isNspawnContainer = true;
  };
}
