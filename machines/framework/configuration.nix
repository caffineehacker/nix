{ pkgs, lib, inputs, ... }:
let 
  kernelPkgs = nixpkgs-unoptimized.linuxPackages_zen;
  nixpkgs-unoptimized = import inputs.nixpkgs {
    inherit (pkgs) system;
  };
  nixpkgs-unoptimized-i686 = import inputs.nixpkgs {
    system = "i686-linux";
  };
in {
  nix = {
    package = pkgs.nixFlakes;
    extraOptions = ''
      experimental-features = nix-command flakes
      # This ensures garbage collection won't collect build dependencies
      keep-outputs = true
      keep-derivations = true
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
  nixpkgs.overlays =
    let 
    # This comes from nixpkgs/pkgs/stdenv/adapters.nix. The primary change is that we don't make a default mkDerivationFromStdenv if stdenvSuperArgs.mkDerivationFromStdenv doesn't exist.
    # Instead, we require the caller to have already used a method like addAttrsToDerivation which will create a default mkDerivationFromStdenv if it doesn't already exist.
    withOldMkDerivation = stdenvSuperArgs: k: stdenvSelf: let
      mkDerivationFromStdenv-super = stdenvSuperArgs.mkDerivationFromStdenv;
      mkDerivationSuper = mkDerivationFromStdenv-super stdenvSelf;
    in
      k stdenvSelf mkDerivationSuper;

    # Wrap the original `mkDerivation` providing extra args to it.
    extendMkDerivationArgs = old: f: withOldMkDerivation old (_: mkDerivationSuper: args:
      (mkDerivationSuper args).overrideAttrs f);

    removeFlagsByPrefix = prefix: flags: lib.lists.foldr (a: b: (if (lib.strings.hasPrefix prefix a) || (a == "") then b else (a + " " + b))) "" (lib.strings.splitString " " flags);

    removeOFlags = flags: removeFlagsByPrefix "-O" flags;
    removeMarchFlags = flags: removeFlagsByPrefix "-mtune=" (removeFlagsByPrefix "-march=" flags);
    removeExistingOptimizations = flags: removeOFlags (removeMarchFlags flags);

    # This is hacky, but just replacing the x86_64 package will cause the i686 package to incorrectly use x86_64-linux system.
    # We also can't directly override the pkgsi686linux and instead have to do this...
    useUnoptimized-x64 = super: pkgs: lib.lists.foldr (a: b: (lib.attrsets.setAttrByPath [a] (lib.attrsets.getAttrFromPath [a] nixpkgs-unoptimized.pkgs)) // b) { } pkgs;
    useUnoptimized-i686 = super: pkgs: lib.lists.foldr (a: b: (lib.attrsets.setAttrByPath [a] (lib.attrsets.getAttrFromPath [a] nixpkgs-unoptimized-i686.pkgs)) // b) { } pkgs;
    useUnoptimized = super: pkgs: if (super.stdenv.system == "x86_64-linux") then (useUnoptimized-x64 super pkgs) else (useUnoptimized-i686 super pkgs);

    useUnoptimizedHaskell-x64 = super: pkgs: lib.lists.foldr (a: b: (lib.attrsets.setAttrByPath [a] (lib.attrsets.getAttrFromPath [a] nixpkgs-unoptimized.pkgs.haskellPackages)) // b) { } pkgs;
    useUnoptimizedHaskell-i686 = super: pkgs: lib.lists.foldr (a: b: (lib.attrsets.setAttrByPath [a] (lib.attrsets.getAttrFromPath [a] nixpkgs-unoptimized-i686.pkgs.haskellPackages)) // b) { } pkgs;
    useUnoptimizedHaskell = super: pkgs: {
      haskellPackages = super.haskellPackages.override{
        overrides = (new: old: (if (super.stdenv.system == "x86_64-linux") then (useUnoptimizedHaskell-x64 super pkgs) else (useUnoptimizedHaskell-i686 super pkgs)));
      };
    };
    in
  [
    (self: super: {
      # This is the same as super.withCFlags, but allows setting the attribute instead of the env for some packages
      # We need to apply addAttrsToDerivation to ensure there is always a mkDerivationFromStdenv already.
      stdenv = (super.addAttrsToDerivation {} super.stdenv).override (old: {
        # Bootstrap compilers don't support lto and don't really need special flags
        mkDerivationFromStdenv = extendMkDerivationArgs old (args:
          let
            enableFlto = false;
            updateMarch = super.stdenv.system == "x86_64-linux";
            removeFunction = if (updateMarch) then removeExistingOptimizations else removeOFlags;
            updateFunction = flags: (removeFunction flags) + " -O3 " + (if updateMarch then " -march=znver4 -mtune=znver4 " else "") + (if enableFlto then " -flto " else "");
          in
            if (lib.strings.hasInfix "bootstrap" old.name) then {} else
              (lib.attrsets.optionalAttrs (args ? "NIX_CFLAGS_COMPILE") {
                NIX_CFLAGS_COMPILE = updateFunction (toString(args.NIX_CFLAGS_COMPILE));
              }) // (lib.attrsets.optionalAttrs (!(args ? "NIX_CFLAGS_COMPILE") || ((args.env or {}) ? "NIX_CFLAGS_LINK")) {
                env = (args.env or {}) // lib.attrsets.optionalAttrs (!(args ? "NIX_CFLAGS_COMPILE")) {
                  NIX_CFLAGS_COMPILE = updateFunction (toString(args.env.NIX_CFLAGS_COMPILE or ""));
                };
              }));
      });
      # Segfault in checks - 4/23/2024
      libvorbis = super.libvorbis.override(old: {
        stdenv = super.withCFlags [ "-march=x86-64 -mtune=generic" ] old.stdenv;
      });
      # Compile error in AVX512 test - 4/23/2024
      simde = super.simde.override(old: {
        stdenv = super.withCFlags [ "-march=x86-64 -mtune=generic" ] old.stdenv;
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
      # Floating point precision test failures - 4/28/2024
      gsl = super.gsl.override(old: {
        stdenv = super.withCFlags ["-march=x86-64" "-mtune=generic" "-mno-fma"] old.stdenv;
      });
      # Floating point precision test failures - 4/28/2024
      lib2geom = super.lib2geom.override(old: {
        stdenv = super.withCFlags ["-march=x86-64" "-mtune=generic" "-mno-fma"] old.stdenv;
      });
      # libgcrypt requires special logic on applying -O flags
      libgcrypt = super.libgcrypt.override(old: {
        stdenv = super.stdenv.override (old: {
        mkDerivationFromStdenv = extendMkDerivationArgs old (args:
            lib.attrsets.optionalAttrs (args ? "NIX_CFLAGS_COMPILE") {
              NIX_CFLAGS_COMPILE = removeOFlags (toString(args.NIX_CFLAGS_COMPILE));
            } // lib.attrsets.optionalAttrs (!(args ? "NIX_CFLAGS_COMPILE")) {
              env = (args.env or {}) // {
                NIX_CFLAGS_COMPILE = removeOFlags (toString(args.env.NIX_CFLAGS_COMPILE));
              };
            });
        });
      });
      # Warning as error about maybe uninitialized variables
      bpftools = super.bpftools.override(old: {
        stdenv = super.stdenv.override (old: {
        mkDerivationFromStdenv = extendMkDerivationArgs old (args:
            lib.attrsets.optionalAttrs (args ? "NIX_CFLAGS_COMPILE") {
              NIX_CFLAGS_COMPILE = toString(args.NIX_CFLAGS_COMPILE) + " -Wno-maybe-uninitialized ";
            } // lib.attrsets.optionalAttrs (!(args ? "NIX_CFLAGS_COMPILE")) {
              env = (args.env or {}) // {
                NIX_CFLAGS_COMPILE = toString(args.env.NIX_CFLAGS_COMPILE) + " -Wno-maybe-uninitialized ";
              };
            });
        });
      });
      # Warning as error about maybe uninitialized variables
      libbpf = super.libbpf.override(old: {
        stdenv = super.stdenv.override (old: {
        mkDerivationFromStdenv = extendMkDerivationArgs old (args:
            lib.attrsets.optionalAttrs (args ? "NIX_CFLAGS_COMPILE") {
              NIX_CFLAGS_COMPILE = toString(args.NIX_CFLAGS_COMPILE) + " -Wno-maybe-uninitialized ";
            } // lib.attrsets.optionalAttrs (!(args ? "NIX_CFLAGS_COMPILE")) {
              env = (args.env or {}) // {
                NIX_CFLAGS_COMPILE = toString(args.env.NIX_CFLAGS_COMPILE) + " -Wno-maybe-uninitialized ";
              };
            });
        });
      });
    })
    (final: super: (useUnoptimized super [
      # These are here because they can be very slow to build
      "nodejs"
      "electron"
      "electron_29"
      "firefox"
      "firefox-bin"
      "webkitgtk"
      "webkitgtk_4_1"
      "webkitgtk_5_0"
      "webkitgtk_6_0"
      # Build failure - 5/8/2024
      "dav1d"
      # Test failure if too many builds are happening at once
      "fprintd"]))
    (final: super: (useUnoptimizedHaskell super [
      # Test failure - 5/8/2024
      "crypton"
      # Test failure - 5/8/2024
      "cryptonite"]))
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
  boot.kernelPackages = kernelPkgs;
  boot.kernelPatches = [
    (lib.mkIf (lib.versionOlder kernelPkgs.kernel.version "6.9")
    {
      name = "cros_ec_lpc";
      patch = (pkgs.fetchpatch {
        url = "https://patchwork.kernel.org/series/840830/mbox/";
        sha256 = "sha256-7jSEAGInFC+a+ozCyD4dFz3Qgh2JrHskwz7UfswizFw=";
      });
    })
  ];
  boot.extraModulePackages = [
      kernelPkgs.framework-laptop-kmod
  ];
  boot.kernelModules = [ "cros_ec" "cros_ec_lpcs" ];
  # We have plenty of ram
  boot.kernel.sysctl = { "vm.swappiness" = 10; };

  tw.system.tpm-unlock.enable = true;
  tw.services.ssh.enable = true;
  tw.services.kdeconnect.enable = true;

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
    nixpkgs-unoptimized.linuxKernel.packages.linux_zen.framework-laptop-kmod
    fw-inputmodule
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

