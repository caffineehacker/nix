# WARNING!!!! You should configure the username and password manually in the config file or else nothing will work. The config file will be created on first launch.

{config, lib, ...}: let
  cfg = config.tw.containers.obsidian-sync;
  helpers = import ./helpers.nix { inherit lib; };
in helpers.mkContainer cfg {
  config = {config, pkgs, lib, ...}: {
    services.couchdb = {
      enable = true;
      bindAddress = "127.0.0.1";
      port = cfg.cloudflare.port;
      # https://github.com/vrtmrz/obsidian-livesync/blob/main/docs/setup_own_server.md#configure
      extraConfig = ''
        [couchdb]
        single_node=true
        max_document_size = 50000000

        [chttpd]
        require_valid_user = true
        max_http_request_size = 4294967296
        enable_cors = true

        [chttpd_auth]
        require_valid_user = true
        authentication_redirect = /_utils/session.html

        [httpd]
        WWW-Authenticate = Basic realm="couchdb"
        enable_cors = true

        [cors]
        credentials = true
        origins = "app://obsidian.md,capacitor://localhost,http://localhost"
      '';
    };
  };
}