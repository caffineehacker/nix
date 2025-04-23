{ pkgs, lib, inputs, ... }:
let
  kernelPkgs = nixpkgs-unoptimized.linuxPackages_zen;
  nixpkgs-unoptimized = import inputs.nixpkgs {
    system = "x86_64-linux";
  };
  nixpkgs-unoptimized-i686 = import inputs.nixpkgs {
    system = "i686-linux";
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
    system = "x86_64-linux";
    gcc.arch = "znver4";
    gcc.tune = "znver4";
  };
  nixpkgs.config.rocmSupport = true;
  nixpkgs.overlays =
    let
      # This comes from nixpkgs/pkgs/stdenv/adapters.nix. The primary change is that we don't make a default mkDerivationFromStdenv if stdenvSuperArgs.mkDerivationFromStdenv doesn't exist.
      # Instead, we require the caller to have already used a method like addAttrsToDerivation which will create a default mkDerivationFromStdenv if it doesn't already exist.
      withOldMkDerivation = stdenvSuperArgs: k: stdenvSelf:
        let
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
      useUnoptimized-x64 = super: pkgs: lib.lists.foldr (a: b: (lib.attrsets.setAttrByPath [ a ] (lib.attrsets.getAttrFromPath [ a ] nixpkgs-unoptimized.pkgs)) // b) { } pkgs;
      useUnoptimized-i686 = super: pkgs: lib.lists.foldr (a: b: (lib.attrsets.setAttrByPath [ a ] (lib.attrsets.getAttrFromPath [ a ] nixpkgs-unoptimized-i686.pkgs)) // b) { } pkgs;
      useUnoptimized = super: pkgs: if (super.stdenv.system == "x86_64-linux") then (useUnoptimized-x64 super pkgs) else (useUnoptimized-i686 super pkgs);

      useUnoptimizedHaskell-x64 = super: pkgs: lib.lists.foldr (a: b: (lib.attrsets.setAttrByPath [ a ] (lib.attrsets.getAttrFromPath [ a ] nixpkgs-unoptimized.pkgs.haskellPackages)) // b) { } pkgs;
      useUnoptimizedHaskell-i686 = super: pkgs: lib.lists.foldr (a: b: (lib.attrsets.setAttrByPath [ a ] (lib.attrsets.getAttrFromPath [ a ] nixpkgs-unoptimized-i686.pkgs.haskellPackages)) // b) { } pkgs;
      useUnoptimizedHaskell = super: pkgs: {
        haskellPackages = super.haskellPackages.override {
          overrides = (new: old: (if (super.stdenv.system == "x86_64-linux") then (useUnoptimizedHaskell-x64 super pkgs) else (useUnoptimizedHaskell-i686 super pkgs)));
        };
      };
    in
    [
      (self: super: {
        # This is the same as super.withCFlags, but allows setting the attribute instead of the env for some packages
        # We need to apply addAttrsToDerivation to ensure there is always a mkDerivationFromStdenv already.
        stdenv = (super.addAttrsToDerivation { } super.stdenv).override (old: {
          # Bootstrap compilers don't support lto and don't really need special flags
          mkDerivationFromStdenv = extendMkDerivationArgs old (args:
            let
              enableFlto = false;
              updateMarch = super.stdenv.system == "x86_64-linux";
              removeFunction = if (updateMarch) then removeExistingOptimizations else removeOFlags;
              updateFunction = flags: (removeFunction flags) + " -O3 " + (if updateMarch then " -march=znver4 -mtune=znver4 " else "") + (if enableFlto then " -flto " else "");
            in
            if (lib.strings.hasInfix "bootstrap" old.name) then { } else
            (lib.attrsets.optionalAttrs (args ? "NIX_CFLAGS_COMPILE") {
              NIX_CFLAGS_COMPILE = updateFunction (toString (args.NIX_CFLAGS_COMPILE));
            }) // (lib.attrsets.optionalAttrs (!(args ? "NIX_CFLAGS_COMPILE") || ((args.env or { }) ? "NIX_CFLAGS_LINK")) {
              env = (args.env or { }) // lib.attrsets.optionalAttrs (!(args ? "NIX_CFLAGS_COMPILE")) {
                NIX_CFLAGS_COMPILE = updateFunction (toString (args.env.NIX_CFLAGS_COMPILE or ""));
              };
            }));
        });
        # Segfault in checks - 4/23/2024
        libvorbis = super.libvorbis.override
          (old: {
            stdenv = super.withCFlags [ "-march=x86-64 -mtune=generic" ] old.stdenv;
          });
        # Compile error in AVX512 test - 4/23/2024
        simde = super.simde.override
          (old: {
            stdenv = super.withCFlags [ "-march=x86-64 -mtune=generic" ] old.stdenv;
          });
        # A test fails due to being too slow while building everything else - 4/24/2024
        pythonPackages.hypothesis = super.pythonPackages.hypothesis.overridePythonAttrs
          {
            doCheck = false;
            pytestCheckPhase = "true";
          };
        pythonPackagesExtensions = super.pythonPackagesExtensions ++ [
          (pyfinal: pysuper: {
            scipy = pysuper.scipy.overridePythonAttrs (oldAttrs: {
              # Tests fail due to floating point precision due to optimizations
              disabledTests = pysuper.scipy.disabledTests ++ [ "test_equal_bounds" ];
            });
          })
        ];
        # A test seg faults - 4/24/2024
        libsndfile = super.libsndfile.override
          (old: {
            stdenv = old.stdenv // { hostPlatform = lib.systems.elaborate { system = "x86_64-linux"; }; };
          });
        # Floating point precision test failures - 4/28/2024
        gsl = super.gsl.override
          (old: {
            stdenv = super.withCFlags [ "-march=x86-64" "-mtune=generic" "-mno-fma" ] old.stdenv;
          });
        # Floating point precision test failures - 4/28/2024
        lib2geom = super.lib2geom.override
          (old: {
            stdenv = super.withCFlags [ "-march=x86-64" "-mtune=generic" "-mno-fma" ] old.stdenv;
          });
        # libgcrypt requires special logic on applying -O flags
        libgcrypt = super.libgcrypt.override (old: {
          stdenv = super.stdenv.override (old: {
            mkDerivationFromStdenv = extendMkDerivationArgs old (args:
              lib.attrsets.optionalAttrs (args ? "NIX_CFLAGS_COMPILE")
                {
                  NIX_CFLAGS_COMPILE = removeOFlags (toString (args.NIX_CFLAGS_COMPILE));
                } // lib.attrsets.optionalAttrs (!(args ? "NIX_CFLAGS_COMPILE")) {
                env = (args.env or { }) // {
                  NIX_CFLAGS_COMPILE = removeOFlags (toString (args.env.NIX_CFLAGS_COMPILE));
                };
              });
          });
        });
        # Warning as error about maybe uninitialized variables
        bpftools = super.bpftools.override (old: {
          stdenv = super.stdenv.override (old: {
            mkDerivationFromStdenv = extendMkDerivationArgs old (args:
              lib.attrsets.optionalAttrs (args ? "NIX_CFLAGS_COMPILE")
                {
                  NIX_CFLAGS_COMPILE = toString (args.NIX_CFLAGS_COMPILE) + " -Wno-maybe-uninitialized ";
                } // lib.attrsets.optionalAttrs (!(args ? "NIX_CFLAGS_COMPILE")) {
                env = (args.env or { }) // {
                  NIX_CFLAGS_COMPILE = toString (args.env.NIX_CFLAGS_COMPILE) + " -Wno-maybe-uninitialized ";
                };
              });
          });
        });
        # Warning as error about maybe uninitialized variables
        libbpf = super.libbpf.override (old: {
          stdenv = super.stdenv.override (old: {
            mkDerivationFromStdenv = extendMkDerivationArgs old (args:
              lib.attrsets.optionalAttrs (args ? "NIX_CFLAGS_COMPILE")
                {
                  NIX_CFLAGS_COMPILE = toString (args.NIX_CFLAGS_COMPILE) + " -Wno-maybe-uninitialized ";
                } // lib.attrsets.optionalAttrs (!(args ? "NIX_CFLAGS_COMPILE")) {
                env = (args.env or { }) // {
                  NIX_CFLAGS_COMPILE = toString (args.env.NIX_CFLAGS_COMPILE) + " -Wno-maybe-uninitialized ";
                };
              });
          });
        });
        # Rocblas takes forever to build and just overriding it does not update the dependency for other packages unfortuntately.
        rocmPackages_6 = nixpkgs-unoptimized.pkgs.rocmPackages_6;
      })
      (final: super: (useUnoptimized super [
        # These are here because they can be very slow to build
        "nodejs"
        "nodejs-slim"
        "electron"
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
        "electron-unwrapped"
        "firefox"
        "firefox-bin"
        "webkitgtk"
        "webkitgtk_4_1"
        "webkitgtk_5_0"
        "webkitgtk_6_0"
        "llvm"
        # Test failure (checkasm) - 02/05/2025
        "dav1d"
        # Fails to build due to expecting BPF support that is apparently not available in clang?? - 02/05/2025
        "systemd"
        # # Fails to build due to aggressive size checks - 02/05/2025
        "libtpms"
        # Fails a test for unknown reason - 02/05/2025
        "lib2geom"
        # Fails to compile due to format overflow - 02/05/2025
        "efivar"
        # Fails a test - 02/04/2025
        "graphene"
        # Fails to find some managed application when building dotnet - 02/04/2025
        "ryujinx"
        # Fails to build a dependency, openexr, that is customized so an override doesn't use the cache - 02/04/2025
        "gst_all_1"
        # Can't have a -march since it is targeting wasm32
        "thunderbird-unwrapped"
      ]))
      (final: super: (useUnoptimizedHaskell super [
        # Test failures - 04/23/2025
        "crypton-x509-validation"
      ]))
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

  # Disable touchpad while typingq
  environment.etc = {
    "libinput/local-overrides.quirks".text = ''
      [Keyboard]
      MatchUdevType=keyboard
      MatchName=Framework Laptop 16 Keyboard Module - ANSI Keyboard
      AttrKeyboardIntegration=internal
    '';
  };

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
  # services.xserver.displayManager.gdm.enable = true;
  services.xserver.desktopManager.gnome.enable = true;

  services.pipewire = {
    alsa = {
      enable = true;
      support32Bit = true;
    };
    pulse = {
      enable = true;
    };
  };

  # Enable touchpad support (enabled default in most desktopManager).
  services.libinput.enable = true;

  tw.users.tim.enable = true;

  environment.systemPackages = with pkgs; [
    # Necessary for Gnome to use the ambient light sensor
    # TODO: Move to a gnome module
    iio-sensor-proxy
    # Framework specific bits
    framework-tool
    nixpkgs-unoptimized.linuxKernel.packages.linux_zen.framework-laptop-kmod
    fw-inputmodule
    sops
    amdgpu_top
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

  services.blueman.enable = true;

  services.logind.extraConfig = ''
    # don't shutdown when power button is short-pressed
    HandlePowerKey=suspend
  '';

  system.stateVersion = "24.05";
}

