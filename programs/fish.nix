{ lib
, pkgs
, config
, ...
}:
let
  cfg = config.tw.programs.fish;

  notFoundScript = pkgs.writeScriptBin "not-found" ''
    #!/usr/bin/env bash
    source ${pkgs.nix-index}/etc/profile.d/command-not-found.sh
    command_not_found_handle "$@"
  '';
in
{
  options = {
    tw.programs.fish.enable = lib.mkOption {
      default = true;
      example = true;
      description = ''
        Enable the fish shell
      '';
      type = lib.types.bool;
    };
  };

  config = lib.mkIf cfg.enable {
    programs.fish = {
      enable = true;

      interactiveShellInit = ''
        function fish_command_not_found
            ${notFoundScript}/bin/not-found $argv
          end
      '';
    };

    # Make fish run for interactive sessions
    programs.bash = {
      interactiveShellInit = ''
        if [[ $(${pkgs.procps}/bin/ps --no-header --pid=$PPID --format=comm) != "fish" && -z ''${BASH_EXECUTION_STRING} ]]
        then
          shopt -q login_shell && LOGIN_OPTION='--login' || LOGIN_OPTION=""
          exec ${pkgs.fish}/bin/fish $LOGIN_OPTION
        fi
      '';
    };

    programs.nix-index.enable = true;

    environment.systemPackages = with pkgs; [
      fishPlugins.done
      fishPlugins.fzf-fish
      fishPlugins.forgit
      fishPlugins.hydro
      fzf
      fishPlugins.grc
      grc
    ];
  };
}
