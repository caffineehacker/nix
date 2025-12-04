{ lib, ... }: {
  module = cfg: { ... }: {
    config = lib.mkIf cfg.enable {
      containers."${cfg.name}" = {
        autoStart = true;
        privateNetwork = true;
        hostAddress = cfg.hostIp;
        localAddress = cfg.containerIp;

        extraFlags =
          if cfg.cloudflare.tunnelFile != null then [
            # Load the cloudflare secret
            "--load-credential=tunnel.json:${cfg.cloudflare.tunnelFile}"
          ] else [ ];
      };
    };
  };

  containerConfigModule = cfg: { config, pkgs, lib, ... }: {
    system.stateVersion = "23.11";

    imports =
      if cfg.cloudflare.tunnelFile != null then [
        ./cloudflared.nix
      ] else [ ];

    tw.containers.cloudflared = lib.mkIf (cfg.cloudflare.tunnelFile != null) {
      tunnelId = cfg.cloudflare.tunnelId;
      hostname = cfg.hostname;
      port = cfg.cloudflare.port;
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
