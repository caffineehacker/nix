{ config, lib, ... }:
let
  cfg = config.tw.containers.actual-budget;
  helpers = import ./helpers.nix { inherit lib; };
in
{
  imports = [ (helpers.module cfg) ];

  config = lib.mkIf cfg.enable {
    containers."${cfg.name}".config = { ... }: {
      imports = [ (helpers.containerConfigModule cfg) ];

      services.actual = {
        enable = true;
        settings.port = cfg.cloudflare.port;
      };
    };
  };
}
