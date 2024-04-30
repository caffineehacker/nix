{ pkgs, lib, inputs, ... }:

{
  nix = {
    package = pkgs.nixFlakes;
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
    settings.trusted-users = ["root" "tim"];
    settings.system-features = ["gccarch-znver4" "benchmark" "big-parallel" "kvm" "nixos-test"];
    settings.show-trace = true;
  };
  nixpkgs.hostPlatform = {
    system = "x86_64-linux";
    gcc.arch = "znver4";
    gcc.tune = "znver4";
  };
  nixpkgs.overlays = [
    (self: super: {
      # stdenv = super.withCFlags [ "-flto" "-funroll-loops" "-O3" ] super.stdenv;
      # Segfault in checks - 4/23/2024
      libvorbis = super.libvorbis.override(old: {
        stdenv = super.addAttrsToDerivation { NIX_CFLAGS_COMPILE = "-march=x86-64 -mtune=x86-64"; } old.stdenv;
      });
      # Compile error in AVX512 test - 4/23/2024
      simde = super.simde.override(old: {
        stdenv = super.addAttrsToDerivation { NIX_CFLAGS_COMPILE = "-march=x86-64 -mtune=x86-64"; } old.stdenv;
      });
      # A test fails due to being too slow while building everything else - 4/24/2024
      pythonPackages.hypothesis = super.pythonPackages.hypothesis.overridePythonAttrs {
        doCheck = false;
        pytestCheckPhase = "true";
      };
      # A test fails due to being too slow while building everything else - 4/24/2024
      python3 = super.python3.override {
        packageOverrides = pfinal: pprev: {
          h2 = pprev.h2.overridePythonAttrs {
            doCheck = false;
            pytestCheckPhase = "true";
            disabledTests = pprev.h2.disabledTests ++ ["test_flow_control_window"];
          };
        };
      };
      # A test seg faults - 4/24/2024
      libsndfile = super.libsndfile.override(old: {
        stdenv = old.stdenv // {hostPlatform = lib.systems.elaborate { system = "x86_64-linux"; };};
      });
      # Doesn't use optimization flags and takes forever to build
      electron-unwrapped = super.electron-unwrapped.override(old: {
        stdenv = old.stdenv // {hostPlatform = lib.systems.elaborate { system = "x86_64-linux"; };};
      });
      # Floating point precision test failures - 4/28/2024
      gsl = super.gsl.override(old: {
        # FIXME: Replay mtune=x86-64 with mtune=generic
        stdenv = super.withCFlags ["-march=x86-64" "-mtune=x86-64" "-mno-fma"] old.stdenv;
      });
      # Floating point precision test failures - 4/28/2024
      lib2geom = super.lib2geom.override(old: {
        stdenv = super.withCFlags ["-march=x86-64" "-mtune=generic" "-mno-fma"] old.stdenv;
      });
    })
  ];

  imports = [
    ../common.nix
    inputs.nixos-hardware.nixosModules.framework-16-7040-amd
  ];

  tw.system.secure-boot.enable = true;
  boot.loader.systemd-boot.configurationLimit = 5;
  boot.loader.systemd-boot.memtest86.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.initrd.systemd.enable = true;
  boot.kernelPackages = pkgs.linuxPackages_zen;
  boot.kernelPatches = [
    {
      name = "cros_ec_lpc_part1";
      patch = ./kernelpatches/cros_ec_lpc_part1.patch;
    }
    {
      name = "cros_ec_lpc_part2";
      patch = ./kernelpatches/cros_ec_lpc_part2.patch;
    }
    {
      name = "cros_ec_lpc_part3";
      patch = ./kernelpatches/cros_ec_lpc_part3.patch;
    }
    {
      name = "cros_ec_lpc_part4";
      patch = ./kernelpatches/cros_ec_lpc_part4.patch;
    }
  ];
  boot.extraModulePackages = [
      pkgs.linuxPackages_zen.framework-laptop-kmod
  ];
  boot.kernelModules = [ "cros_ec" "cros_ec_lpcs" ];

  tw.system.tpm-unlock.enable = true;

  networking.hostName = "framework";

  # Enable the X11 windowing system.
  services.xserver.enable = true;


  # Enable the GNOME Desktop Environment.
  # services.xserver.displayManager.gdm.enable = true;
  services.xserver.desktopManager.gnome.enable = true;

  # Enable sound.
  sound.enable = true;
  hardware.pulseaudio.enable = true;

  # Enable touchpad support (enabled default in most desktopManager).
  services.xserver.libinput.enable = true;

  tw.users.tim.enable = true;

  environment.systemPackages = with pkgs; [
    # Necessary for Gnome to use the ambient light sensor
    # TODO: Move to a gnome module
    iio-sensor-proxy
    # Framework specific bits
    framework-tool
    linuxKernel.packages.linux_zen.framework-laptop-kmod
  ];

  tw.programs.games.enable = true;
  tw.programs.hyprland.enable = true;

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  services.fwupd.enable = true;

  # AMD has better battery life with PPD over TLP:
  # https://community.frame.work/t/responded-amd-7040-sleep-states/38101/13
  services.power-profiles-daemon.enable = true;

  # For fingerprint support
  services.fprintd.enable = true;

  # Needed for desktop environments to detect/manage display brightness
  hardware.sensor.iio.enable = true;

  # Trim ssd for longer life and better storage
  services.fstrim.enable = true;

  # Enable non-root access to QMK firmware
  hardware.keyboard.qmk.enable = true;

  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;

  services.blueman.enable = true;

  services.logind.extraConfig = ''
    # don't shutdown when power button is short-pressed
    HandlePowerKey=suspend
  '';

  system.stateVersion = "23.11";
}

