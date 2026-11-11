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
      lto = true;
    };
    system = "x86_64-linux";
  };
  nixpkgs.config = {
    rocmSupport = true;
  };
  nixpkgs.overlays =
    let
      useUnoptimized-x64 = prev: pkgs: if (prev.stdenv.system == "x86_64-linux") then (lib.lists.foldr (a: b: (lib.attrsets.setAttrByPath [ a ] (lib.attrsets.getAttrFromPath [ a ] nixpkgs-unoptimized.pkgs)) // b) { } pkgs) else { };
      useUnoptimized-i686 = prev: pkgs: if (prev.stdenv.system == "x86_64-linux") then { } else (lib.lists.foldr (a: b: (lib.attrsets.setAttrByPath [ a ] (lib.attrsets.getAttrFromPath [ a ] nixpkgs-unoptimized.pkgs.pkgsi686Linux)) // b) { } pkgs);
      disableLlvmCheck = llvmPackages:
        let
          overridden = llvmPackages.overrideScope (lfinal: lprev: {
            libllvm = lprev.libllvm.overrideAttrs (finalAttrs: prevAttrs: {
              doCheck = false;
            });
          });
        in
        overridden // {
          override = args: disableLlvmCheck (llvmPackages.override args);
        };
      disableOpenjdkLto = pkg:
        let
          patched = pkg.overrideAttrs (finalAttrs: prevAttrs: {
            env = (prevAttrs.env or { }) // {
              NIX_CFLAGS_COMPILE = (prevAttrs.env.NIX_CFLAGS_COMPILE or "") + " -fno-lto";
            };
          });
        in
        patched
        // lib.optionalAttrs (pkg ? headless) {
          headless = disableOpenjdkLto pkg.headless;
        }
        // lib.optionalAttrs (pkg ? override) {
          override = args: disableOpenjdkLto (pkg.override args);
        };
      enableFfmpegLto = pkg:
        let
          patched = pkg.overrideAttrs (finalAttrs: prevAttrs: {
            configureFlags = (prevAttrs.configureFlags or [ ]) ++ [ "--enable-lto=auto" ];
          });
        in
        patched
        // lib.optionalAttrs (pkg ? override) {
          override = args: enableFfmpegLto (pkg.override args);
        };
      patchQt5Base = pkg:
        let
          patched = pkg.overrideAttrs (finalAttrs: prevAttrs: {
            postPatch = (prevAttrs.postPatch or "") + "\n" + ''
              substituteInPlace src/corelib/global/global.pri \
                --replace-fail "gcc:ltcg {" "gcc {"
              substituteInPlace mkspecs/features/simd.prf \
                --replace-fail 'ltcg: cflags += $$QMAKE_CFLAGS_DISABLE_LTCG' 'cflags += $$QMAKE_CFLAGS_DISABLE_LTCG'
              substituteInPlace mkspecs/features/resources.prf \
                --replace-fail "!resources_big|ltcg|" "!resources_big|gcc|ltcg|"
            '';
          });
        in
        patched
        // lib.optionalAttrs (pkg ? override) {
          override = args: patchQt5Base (pkg.override args);
        };
      disableZigLto = pkg:
        let
          patched = pkg.overrideAttrs (finalAttrs: prevAttrs: {
            env = (prevAttrs.env or { }) // {
              NIX_CFLAGS_COMPILE = (prevAttrs.env.NIX_CFLAGS_COMPILE or "") + " -fno-lto";
            };
          });
        in
        patched
        // lib.optionalAttrs (pkg ? override) {
          override = args: disableZigLto (pkg.override args);
        };
    in
    [
      (final: prev: {
        # This seems to customize the rocmPackages when built with rocm support (actually it's the onnxruntime dependency) - 11/14/2025
        thunderbird = nixpkgs-without-rocm.thunderbird;
      })
      (final: prev:
        (if prev.stdenv.system == "x86_64-linux" then {
          pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
            # Fails tests - 2/27/2026
            (pyfinal: pyprev: {
              psycopg = pyprev.psycopg.overridePythonAttrs (oldAttrs: {
                # Tests fail due to timing issues
                disabledTests = pyprev.psycopg.disabledTests ++ [ "test_stats_connect[asyncio]" "test_stats_connect" "test_remote_closed" ];
              });
            })
          ];
          python3Packages = prev.python3Packages.overrideScope (pyFinal: pyPrev: {
            # This causes qtwebengine to rebuild which takes too long. See https://github.com/NixOS/nixpkgs/issues/330736 for why it causes that.
            pyside6 = nixpkgs-unoptimized.pkgs.python3Packages.pyside6;
          });
          # Top-level asm(".symver ...") in src/libaio.h is invisible to LTO without __attribute__((symver))
          libaio = prev.libaio.overrideAttrs (finalAttrs: prevAttrs: {
            env = (prevAttrs.env or { }) // {
              NIX_CFLAGS_COMPILE = (prevAttrs.env.NIX_CFLAGS_COMPILE or "") + " -fno-lto";
            };
          });
          # Top-level asm in ldso/dlstart.c references _dlstart_c without __attribute__((used))
          musl = prev.musl.overrideAttrs (finalAttrs: prevAttrs: {
            env = (prevAttrs.env or { }) // {
              NIX_CFLAGS_COMPILE = (prevAttrs.env.NIX_CFLAGS_COMPILE or "") + " -fno-lto";
            };
          });
          # Valgrind's freestanding memcheck-amd64-linux uses top-level asm VG_MINIMAL_SETJMP and no libc memcpy
          valgrind = prev.valgrind.overrideAttrs (finalAttrs: prevAttrs: {
            env = (prevAttrs.env or { }) // {
              NIX_CFLAGS_COMPILE = (prevAttrs.env.NIX_CFLAGS_COMPILE or "") + " -fno-lto";
            };
          });
          # Kbuild incremental links (cc -nostdlib -r) on empty/minimal translation units fail in ld.bfd LTO plugin
          busybox = prev.busybox.overrideAttrs (finalAttrs: prevAttrs: {
            env = (prevAttrs.env or { }) // {
              NIX_CFLAGS_COMPILE = (prevAttrs.env.NIX_CFLAGS_COMPILE or "") + " -fno-lto";
            };
          });
          # waiter_test_wrap uses -Wl,--wrap=chef_cook which breaks if LTO inlines chef_cook
          cmocka = prev.cmocka.overrideAttrs (finalAttrs: prevAttrs: {
            env = (prevAttrs.env or { }) // {
              NIX_CFLAGS_COMPILE = (prevAttrs.env.NIX_CFLAGS_COMPILE or "") + " -fno-lto";
            };
          });
          # GCC 16 LTO interprocedural analysis triggers -Werror=stringop-overread in tests
          cjson = prev.cjson.overrideAttrs (finalAttrs: prevAttrs: {
            env = (prevAttrs.env or { }) // {
              NIX_CFLAGS_COMPILE = (prevAttrs.env.NIX_CFLAGS_COMPILE or "") + " -Wno-error=stringop-overread";
            };
          });
          # GCC 16 LTO interprocedural analysis triggers -Werror=stringop-overflow and -Werror=maybe-uninitialized
          usrsctp = prev.usrsctp.overrideAttrs (finalAttrs: prevAttrs: {
            env = (prevAttrs.env or { }) // {
              NIX_CFLAGS_COMPILE = (prevAttrs.env.NIX_CFLAGS_COMPILE or "") + " -Wno-error";
            };
          });
          # Prevent parallel checkPhase race when libtool wrappers first link .libs/lt-gnutls-* with LTO
          gnutls = prev.gnutls.overrideAttrs (finalAttrs: prevAttrs: {
            preCheck = (prevAttrs.preCheck or "") + "\n" + ''
              for prog in src/gnutls-serv src/gnutls-cli src/gnutls-cli-debug src/certtool; do
                if [ -x "$prog" ]; then "$prog" --version >/dev/null 2>&1 || true; fi
              done
            '';
          });
          # tests/run-strip-g.sh compiles a test a.out with "$CC -g -xc -" and expects no LTO debug symbols in .symtab
          elfutils = prev.elfutils.overrideAttrs (finalAttrs: prevAttrs: {
            preCheck = (prevAttrs.preCheck or "") + "\n" + ''
              export NIX_CFLAGS_COMPILE="''${NIX_CFLAGS_COMPILE:-} -fno-lto"
            '';
          });
          # test/unit/fapi-{helpers,config,profiles} use -Wl,--wrap=ifapi_io_read_finish / ifapi_crypto_hash_*,
          # which breaks if LTO inlines the wrapped functions across translation units when compiling check_PROGRAMS in installCheckPhase
          tpm2-tss = prev.tpm2-tss.overrideAttrs (finalAttrs: prevAttrs: {
            preInstallCheck = (prevAttrs.preInstallCheck or "") + "\n" + ''
              export NIX_CFLAGS_COMPILE="''${NIX_CFLAGS_COMPILE:-} -fno-lto"
            '';
          });
          # LibreSSL's m4/check-os-options.m4 sets -fno-strict-aliasing, but its CMakeLists.txt omits it on Linux;
          # LTO inlining CRYPTO_cbc128_encrypt (size_t*) + Camellia_encrypt (u32*) triggers TBAA miscompilation without it
          libressl = prev.libressl.overrideAttrs (finalAttrs: prevAttrs: {
            env = (prevAttrs.env or { }) // {
              NIX_CFLAGS_COMPILE = (prevAttrs.env.NIX_CFLAGS_COMPILE or "") + " -fno-strict-aliasing";
            };
          });
          # GHC's deriveConstants inspects SHN_COMMON symbol sizes via nm, which liblto_plugin.so reports as 0 on LTO IR
          haskell = prev.haskell // {
            compiler = prev.haskell.compiler // {
              ghc9103 = prev.haskell.compiler.ghc9103.overrideAttrs (finalAttrs: prevAttrs: {
                env = (prevAttrs.env or { }) // {
                  NIX_CFLAGS_COMPILE = (prevAttrs.env.NIX_CFLAGS_COMPILE or "") + " -fno-lto";
                };
              });
            };
            packages = prev.haskell.packages // {
              ghc9103 = prev.haskell.packages.ghc9103.override (old: {
                overrides = prev.lib.composeExtensions (old.overrides or (_: _: { })) (hfinal: hprev: {
                  # cbits/decaf/include/constant_time.h accesses gf (uint64_t limb[8]) via big_register_t* (uint32x8_t*),
                  # violating C strict aliasing when LTO inlines f_impl.c into decaf.c under -O3
                  crypton = hprev.crypton.overrideAttrs (finalAttrs: prevAttrs: {
                    env = (prevAttrs.env or { }) // {
                      NIX_CFLAGS_COMPILE = (prevAttrs.env.NIX_CFLAGS_COMPILE or "") + " -fno-strict-aliasing";
                    };
                  });
                  cryptonite = hprev.cryptonite.overrideAttrs (finalAttrs: prevAttrs: {
                    env = (prevAttrs.env or { }) // {
                      NIX_CFLAGS_COMPILE = (prevAttrs.env.NIX_CFLAGS_COMPILE or "") + " -fno-strict-aliasing";
                    };
                  });
                  # cbits/bitvec_simd.c uses __builtin_cpu_supports(), which lto1 lowers to __cpu_model (in libgcc.a)
                  # after ld.gold has already resolved archive symbols
                  bitvec = hprev.bitvec.overrideAttrs (finalAttrs: prevAttrs: {
                    env = (prevAttrs.env or { }) // {
                      NIX_CFLAGS_COMPILE = (prevAttrs.env.NIX_CFLAGS_COMPILE or "") + " -fno-lto";
                    };
                  });
                });
              });
            };
          };
          # protobuf_BUILD_TESTS links a huge full-test binary (2.5h+ with LTO) and races on /build/proto2_cli_test_temp
          protobuf = prev.protobuf.overrideAttrs (finalAttrs: prevAttrs: {
            doCheck = false;
          });
          protobuf_36 = prev.protobuf_36.overrideAttrs (finalAttrs: prevAttrs: {
            doCheck = false;
          });
          protobuf_33 = prev.protobuf_33.overrideAttrs (finalAttrs: prevAttrs: {
            doCheck = false;
          });
          # Node.js's tools/v8_gypfiles/v8.gyp only adds -fno-lto to v8_heap_base (push_registers_asm.cc,
          # which defines PushAllRegistersAndIterateStack in top-level asm) and -fno-lto to intermediate
          # generator/test ldflags (mksnapshot, torque, cctest) when --enable-lto is passed to configure.py.
          # Disable checkPhase after verifying cctest + 5411/5416 JS tests pass (test-runner-* times out under heavy parallel build load).
          nodejs-slim_22 = prev.nodejs-slim_22.overrideAttrs (finalAttrs: prevAttrs: {
            configureFlags = (prevAttrs.configureFlags or [ ]) ++ [ "--enable-lto" ];
            doCheck = false;
            postPatch = (prevAttrs.postPatch or "") + "\n" + ''
              substituteInPlace common.gypi --replace-fail " -flto=4 -ffat-lto-objects " " -flto=auto -ffat-lto-objects "
            '';
          });
          nodejs-slim_24 = prev.nodejs-slim_24.overrideAttrs (finalAttrs: prevAttrs: {
            configureFlags = (prevAttrs.configureFlags or [ ]) ++ [ "--enable-lto" ];
            doCheck = false;
            postPatch = (prevAttrs.postPatch or "") + "\n" + ''
              substituteInPlace common.gypi --replace-fail " -flto=4 -ffat-lto-objects " " -flto=auto -ffat-lto-objects "
            '';
          });
          nodejs-slim_26 = prev.nodejs-slim_26.overrideAttrs (finalAttrs: prevAttrs: {
            configureFlags = (prevAttrs.configureFlags or [ ]) ++ [ "--enable-lto" ];
            doCheck = false;
            postPatch = (prevAttrs.postPatch or "") + "\n" + ''
              substituteInPlace common.gypi --replace-fail " -flto=4 -ffat-lto-objects " " -flto=auto -ffat-lto-objects "
            '';
          });
          # onetbb's conformance_parallel_pipeline hangs for 4h+ in checkPhase with HWLOC_SYNTHETIC="node:1 core:1 pu:1"
          onetbb = prev.onetbb.overrideAttrs (finalAttrs: prevAttrs: {
            doCheck = false;
          });
          # GCC LTO's ipa-visibility pass promotes llvm::Any::TypeId<llvm::PreservedAnalyses>::Id in libLLVM.so
          # from weak/unique (u/v/V) to strong initialized data (D), which trips test/tools/llvm-shlib/typeids.test;
          # setting doCheck = false also sets -DLLVM_BUILD_TESTS=FALSE and -DLLVM_INCLUDE_TESTS=FALSE, saving ~3.5h per LLVM version.
          llvmPackages_20 = disableLlvmCheck prev.llvmPackages_20;
          llvmPackages_21 = disableLlvmCheck prev.llvmPackages_21;
          llvmPackages_22 = disableLlvmCheck prev.llvmPackages_22;
          # When cc-rs compiles C -sys crates (like libssh2-sys + libgit2-sys) with GCC -flto=auto and rustc
          # repacks them into .rlib archives, ld.bfd + liblto_plugin.so's two-pass LTO archive resolution collides
          # if a shared library later on the link line (like libcurl.so -> libssh2.so.1) references those symbols.
          # Since rustc uses LLVM and cannot perform cross-language LTO with GCC anyway, pass -fno-lto in Cargo build hooks.
          makeRustPlatform = args: (prev.makeRustPlatform args).overrideScope (rfinal: rprev:
            let
              disableHookLto = hook: hook.overrideAttrs (old: {
                setEnv = (old.setEnv or "") + ''  "NIX_CFLAGS_COMPILE=''${NIX_CFLAGS_COMPILE:-} -fno-lto" \'' + "\n";
              });
            in
            {
              cargoBuildHook = disableHookLto rprev.cargoBuildHook;
              cargoCheckHook = disableHookLto rprev.cargoCheckHook;
              maturinBuildHook = disableHookLto rprev.maturinBuildHook;
            }
          );
          # OpenJDK HotSpot explicitly filters out link-time-opt on x86_64 (make/autoconf/jvm-features.m4) because
          # _get_previous_fp() in os_linux_x86.cpp relies on non-LTO frame inlining and uninitialized register asm,
          # HotSpot omits -fno-strict-aliasing when link-time-opt is not selected via its own feature flag, and
          # linking libjvm.so with 16 parallel lto1 processes triggers OOM kills.
          javaPackages = prev.javaPackages // {
            compiler = prev.javaPackages.compiler // {
              openjdk8 = disableOpenjdkLto prev.javaPackages.compiler.openjdk8;
              openjdk11 = disableOpenjdkLto prev.javaPackages.compiler.openjdk11;
              openjdk17 = disableOpenjdkLto prev.javaPackages.compiler.openjdk17;
              openjdk21 = disableOpenjdkLto prev.javaPackages.compiler.openjdk21;
              openjdk25 = disableOpenjdkLto prev.javaPackages.compiler.openjdk25;
            };
          };
          # FFmpeg's libavcodec/x86/lpc_init.c uses MANGLE(pd_1) in inline asm, which emits direct symbol
          # references ("pd_1(%rip)") instead of LTO-safe named asm constraints ("%[pd_1]") unless
          # --enable-lto=auto is passed to configure (which runs `disable inline_asm_direct_symbol_refs`).
          ffmpeg_4 = enableFfmpegLto prev.ffmpeg_4;
          ffmpeg_4-headless = enableFfmpegLto prev.ffmpeg_4-headless;
          ffmpeg_4-full = enableFfmpegLto prev.ffmpeg_4-full;
          ffmpeg_6 = enableFfmpegLto prev.ffmpeg_6;
          ffmpeg_6-headless = enableFfmpegLto prev.ffmpeg_6-headless;
          ffmpeg_6-full = enableFfmpegLto prev.ffmpeg_6-full;
          ffmpeg_7 = enableFfmpegLto prev.ffmpeg_7;
          ffmpeg_7-headless = enableFfmpegLto prev.ffmpeg_7-headless;
          ffmpeg_7-full = enableFfmpegLto prev.ffmpeg_7-full;
          ffmpeg_8 = enableFfmpegLto prev.ffmpeg_8;
          ffmpeg_8-headless = enableFfmpegLto prev.ffmpeg_8-headless;
          ffmpeg_8-full = enableFfmpegLto prev.ffmpeg_8-full;
          ffmpeg_9 = enableFfmpegLto prev.ffmpeg_9;
          ffmpeg_9-headless = enableFfmpegLto prev.ffmpeg_9-headless;
          ffmpeg_9-full = enableFfmpegLto prev.ffmpeg_9-full;
          ffmpeg = enableFfmpegLto prev.ffmpeg;
          ffmpeg-headless = enableFfmpegLto prev.ffmpeg-headless;
          ffmpeg-full = enableFfmpegLto prev.ffmpeg-full;
          # Qt5's src/corelib/global/qversiontagging.cpp uses top-level asm(".symver ...") which fails under
          # LTO partitioning unless compiled with -fno-lto (handled by global.pri's gcc:ltcg block).
          # Qt5's qtscript (JavaScriptCore/jit/JITStubs.cpp) calls cti_vm_throw from top-level inline asm
          # (ctiVMThrowTrampoline) without __attribute__((used)), so GCC LTO eliminates cti_vm_throw.
          qt5 = prev.qt5.overrideScope (qfinal: qprev: {
            qtbase = patchQt5Base qprev.qtbase;
            qtscript = qprev.qtscript.overrideAttrs (finalAttrs: prevAttrs: {
              env = (prevAttrs.env or { }) // {
                NIX_CFLAGS_COMPILE = (prevAttrs.env.NIX_CFLAGS_COMPILE or "") + " -fno-lto";
              };
            });
            qttranslations =
              let
                bootstrapScope = qfinal.overrideScope (bfinal: bprev: {
                  qtbase = bprev.qtbase.override { qttranslations = null; };
                  qtdeclarative = null;
                });
              in
              bootstrapScope.callPackage ({ qtModule, qttools }: qtModule {
                pname = "qttranslations";
                nativeBuildInputs = [ qttools ];
                outputs = [ "out" ];
              }) { };
          });
          # Waybar's libcava subproject uses INCTXT (.incbin) in config.c with paths relative to
          # subprojects/cava-*, which fails at link time when lto-wrapper runs `as` from the Meson build dir.
          waybar = prev.waybar.overrideAttrs (finalAttrs: prevAttrs: {
            postPatch = (prevAttrs.postPatch or "") + "\n" + ''
              if [ -f subprojects/cava-*/meson.build ]; then
                substituteInPlace subprojects/cava-*/meson.build \
                  --replace-fail "c_args = [" "c_args = ['-fno-lto', "
              fi
            '';
          });
          # Zig's stage2 bootstrap compiler (zig2) links 80+ LLVM/Clang/LLD static archives; running GCC LTO
          # across them triggers a two-pass LTO archive rescan failure on libLLVMCodeGen.a(GCMetadataPrinter.cpp.o).
          # Passing -fno-lto links zig2 directly from the fat ELF sections while stage3/bin/zig still uses LLVM.
          zig_0_13 = disableZigLto prev.zig_0_13;
          zig_0_14 = disableZigLto prev.zig_0_14;
          zig_0_15 = disableZigLto prev.zig_0_15;
          zig_0_16 = disableZigLto prev.zig_0_16;
          zig_0_17 = disableZigLto prev.zig_0_17;
        } else {
          # x86 overrides
          # Tests fail due to timing sensitivity - 04/29/2026
          openldap = prev.openldap.overrideAttrs (finalAttrs: prevAttrs: {
            doCheck = false;
          });
        }) //
        (useUnoptimized-x64 prev [
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
          "electron_42"
          "electron_43"
          "electron_44"
          "electron_45"
          "electron_46"
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
          # Fails a fuzzing test - 09/17/2026
          "ada"
          # If we don't do this then we can't safely override python packages without possibly mixing python runtimes
          "python3"
          "python314"
          # Segfaults in builds and tests that depend on this - 10/8/2026
          "zopfli"
          # Odd test failures - 10/8/2026
          "tinysparql"
          # Fails to convert an XML file?? - 10/8/2026
          "networkmanager"
          # Seems to be used by builds that are failing - 10/8/2026
          "blueprint-compiler"
          "glib"
          "gobject-introspection"
          "gjs"
          # Test failure due to floating point math - 10/23/2026
          "libjpeg_turbo"
          # Fails now.ck check after Nov 1, 2026 due to wall-clock timestamp check - 11/06/2026
          "tzdata"
          # PHP Zend VM uses GCC global register variables (__asm__(ZEND_VM_FP_GLOBAL_REG)) which fail under LTO
          "php"
          "php83"
          "php84"
          "php85"
        ]) //
        (useUnoptimized-i686 prev [ ]))
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
  boot.kernelPackages = kernelPkgs;
  boot.extraModulePackages = [
    kernelPkgs.framework-laptop-kmod
  ];
  boot.kernelModules = [ "cros_ec" "cros_ec_lpcs" ];
  # We have plenty of ram
  boot.kernel.sysctl = { "vm.swappiness" = 10; };
  # Allow building of aarch64-linux binaries. This is slow, but works better than using the remote host.
  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];
  boot.blacklistedKernelModules = [ "ucsi_acpi" ];

  tw.system.tpm-unlock.enable = true;
  tw.services.ssh.enable = true;
  tw.services.kdeconnect.enable = true;
  tw.services.waydroid.enable = true;

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

