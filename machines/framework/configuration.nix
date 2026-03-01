{ pkgs, lib, inputs, config, ... }:
let
  kernelPkgs = nixpkgs-unoptimized.linuxPackages_zen;
  nixpkgs-unoptimized = import inputs.nixpkgs {
    system = "x86_64-linux";
    config = config.nixpkgs.config;
  };
  nixpkgs-without-rocm = import inputs.nixpkgs {
    system = "x86_64-linux";
    config = config.nixpkgs.config // {
      rocmSupport = false;
    };
  };
in
{
  nix = {
    package = pkgs.nixVersions.stable;
    extraOptions = ''
      experimental-features = nix-command flakes
      # This ensures garbage collection won't collect build dependencies
      keep-outputs = true
      keep-derivations = true
    '';
    settings.trusted-users = [ "root" "tim" ];
    settings.system-features = [ "gccarch-znver4" "benchmark" "big-parallel" "kvm" "nixos-test" ];
    settings.show-trace = true;
  };
  nixpkgs.hostPlatform = {
    gcc = {
      arch = "znver4";
      tune = "znver4";
    };
    system = "x86_64-linux";
  };
  nixpkgs.config.rocmSupport = true;
  nixpkgs.overlays =
    let
      useUnoptimized-x64 = pkgs: lib.lists.foldr (a: b: (lib.attrsets.setAttrByPath [ a ] (lib.attrsets.getAttrFromPath [ a ] nixpkgs-unoptimized.pkgs)) // b) { } pkgs;
      useUnoptimized-i686 = pkgs: lib.lists.foldr (a: b: (lib.attrsets.setAttrByPath [ a ] (lib.attrsets.getAttrFromPath [ a ] nixpkgs-unoptimized.pkgs.pkgsi686linux)) // b) { } pkgs;
    in
    [
      (final: prev: {
        # This seems to customize the rocmPackages when built with rocm support (actually it's the onnxruntime dependency) - 11/14/2025
        thunderbird = nixpkgs-without-rocm.thunderbird;
      })
      (final: prev:
        if prev.stdenv.system == "x86_64-linux" then
          {
            pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
              # Fails tests - 2/27/2026
              (pyfinal: pyprev: {
                psycopg = pyprev.psycopg.overridePythonAttrs (oldAttrs: {
                  # Tests fail due to timing issues
                  disabledTests = pyprev.psycopg.disabledTests ++ [ "test_stats_connect[asyncio]" "test_stats_connect" ];
                });
              })
            ];
          } //
          (useUnoptimized-x64 [
            # Rocblas takes forever to build and just overriding it does not update the dependency for other packages unfortuntately.
            "rocmPackages_6"
            "rocmPackages"
            # Fails due to a string overflow warning as error - 02/05/2025
            "libtpms"
            # Test failures - 7/8/2025
            "assimp"
            # Test failures - 02/22/2026
            "gsl"
            # Fails a test for unknown reason - 02/05/2025
            "lib2geom"
            # Some of these don't exist yet, but will help prevent issues when they do
            "electron_29"
            "electron_30"
            "electron_31"
            "electron_32"
            "electron_33"
            "electron_34"
            "electron_35"
            "electron_36"
            "electron_37"
            "electron_38"
            "electron_39"
            "electron_40"
            "electron_41"
            "electron-unwrapped"
            "webkitgtk"
            "webkitgtk_4_1"
            "webkitgtk_5_0"
            "webkitgtk_6_0"
            # Fails due to variable type conversion issues - 02/23/2026
            "mesa"
            # # Complains of symbols in wrong format - 2/23/2026
            # "swtpm"
            # Fails to build due to variable sizes - 2/23/2026
            "simde"
            # Test failures - 3/1/2026
            "valkey"
          ]) else (useUnoptimized-i686 [ ]))
    ];

  imports = [
    ../common.nix
    inputs.nixos-hardware.nixosModules.framework-16-7040-amd
  ];

  tw.system.secure-boot.enable = true;
  security.tpm2.enable = true;
  boot.loader.systemd-boot.configurationLimit = 5;
  boot.loader.systemd-boot.memtest86.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.initrd.systemd.enable = true;
  boot.kernelPackages = kernelPkgs;
  boot.extraModulePackages = [
    kernelPkgs.framework-laptop-kmod
  ];
  boot.kernelModules = [ "cros_ec" "cros_ec_lpcs" ];
  # We have plenty of ram
  boot.kernel.sysctl = { "vm.swappiness" = 10; };
  # Allow building of aarch64-linux binaries. This is slow, but works better than using the remote host.
  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

  tw.system.tpm-unlock.enable = true;
  tw.services.ssh.enable = true;
  tw.services.kdeconnect.enable = true;

  networking.hostName = "framework";

  # Enable the X11 windowing system.
  services.xserver.enable = true;

  # Disable touchpad while typing
  # environment.etc = {
  #   "libinput/local-overrides.quirks".text = ''
  #     [Keyboard]
  #     MatchUdevType=keyboard
  #     MatchName=Framework Laptop 16 Keyboard Module - ANSI Keyboard
  #     AttrKeyboardIntegration=internal
  #   '';
  # };

  # Disable the internal monitor and fingerprint sensor when lid is closed
  services.acpid = {
    enable = true;
    handlers.lidClosed = {
      event = "button/lid \\w+ close";
      action = ''
        echo "Lid closed. Disabling fprintd."
        systemctl stop fprintd
        ln -s /dev/null /run/systemd/transient/fprintd.service
        systemctl daemon-reload
      '';
    };
    handlers.lidOpen = {
      event = "button/lid \\w+ open";
      action = ''
        if ! $(systemctl is-active --quiet fprintd); then
          echo "Lid open. Enabling fprintd."
          rm -f /run/systemd/transient/fprintd.service
          systemctl daemon-reload
          systemctl start fprintd
        fi
      '';
    };
  };

  # Enable the GNOME Desktop Environment.
  services.desktopManager.gnome.enable = true;

  services.pipewire = {
    alsa = {
      enable = true;
      support32Bit = true;
    };
    pulse = {
      enable = true;
    };
  };
  # Enable real time audio
  security.rtkit.enable = true;

  # Enable touchpad support (enabled default in most desktopManager).
  services.libinput.enable = true;

  tw.users.tim.enable = true;
  tw.users.deanna.enable = true;

  environment.systemPackages = with pkgs; [
    # Necessary for Gnome to use the ambient light sensor
    # TODO: Move to a gnome module
    iio-sensor-proxy
    # Framework specific bits
    framework-tool
    nixpkgs-unoptimized.linuxKernel.packages.linux_zen.framework-laptop-kmod
    sops
    amdgpu_top
    easyeffects
  ];

  tw.programs.games.enable = true;
  services.sunshine = {
    enable = true;
    capSysAdmin = true;
    autoStart = false;
    # We open the ports, but don't enable autostart so there will only be something listening when we're at home
    openFirewall = true;
  };
  tw.programs.hyprland.enable = true;

  services.fwupd.enable = true;
  # Framework puts updates here
  services.fwupd.extraRemotes = [ "lvfs" "lvfs-testing" ];

  # AMD has better battery life with PPD over TLP:
  # https://community.frame.work/t/responded-amd-7040-sleep-states/38101/13
  services.power-profiles-daemon.enable = true;
  # Allow fine grained power control
  # Enabling overdrive causes the laptop screen backlight to not turn off during sleep
  # hardware.amdgpu.overdrive.enable = true;
  services.lact.enable = true;
  hardware.fw-fanctrl.enable = true;

  # For fingerprint support
  services.fprintd.enable = true;

  # Needed for desktop environments to detect/manage display brightness
  hardware.sensor.iio.enable = true;

  # Trim ssd for longer life and better storage
  services.fstrim.enable = true;

  # Enable non-root access to QMK firmware
  hardware.keyboard.qmk.enable = true;
  services.hardware.openrgb =
    {
      enable = true;
      package = pkgs.openrgb-with-all-plugins;
      motherboard = "amd";
    };

  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;

  hardware.xone.enable = true;

  services.blueman.enable = true;

  # Automatically deduplicate files
  nix.settings.auto-optimise-store = true;

  # services.logind.extraConfig = ''
  #   # don't shutdown when power button is short-pressed
  #   HandlePowerKey=suspend
  # '';

  system.stateVersion = "24.05";
}

