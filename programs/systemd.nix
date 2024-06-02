{ lib
, pkgs
, config
, inputs
, ...
}:
let
  cfg = config.tw.programs.systemd;
in
{
  options = {
    tw.programs.systemd.nextVersion.enable = lib.mkOption {
      default = false;
      example = true;
      description = ''
        Enable version 256 so that we can use the better way of setting wireguard private keys
      '';
      type = lib.types.bool;
    };
  };

  config = lib.mkIf cfg.nextVersion.enable {
    # This version of systemd supports loading the private key for wireguard networks in a better way. We only need it until 266 releases.
    systemd.package = (pkgs.systemd.overrideAttrs (oldAttrs: finalAttrs: {
      version = "256-rc3";
      src = pkgs.fetchFromGitHub {
        owner = "systemd";
        repo = "systemd-stable";
        rev = "v256-rc3";
        hash = "sha256-dI4Z9ode4tIqdRQF8ernBz9TALDKTeJ93rZU+D/nITQ=";
      };
      patches = [ ./systemd-combined.patch ];
      postPatch = ''
        substituteInPlace src/basic/path-util.h --replace "@defaultPathNormal@" "${placeholder "out"}/bin/"
      '' + ''
        substituteInPlace meson.build \
          --replace "find_program('clang'" "find_program('${pkgs.systemd.stdenv.cc.targetPrefix}clang'"
      '' + (
        let
          # The following patches references to dynamic libraries to ensure that all
          # the features that are implemented via dlopen(3) are available (or
          # explicitly deactivated) by pointing dlopen to the absolute store path
          # instead of relying on the linkers runtime lookup code.
          #
          # All of the shared library references have to be handled. When new ones
          # are introduced by upstream (or one of our patches) they must be
          # explicitly declared, otherwise the build will fail.
          #
          # As of systemd version 247 we've seen a few errors like `libpcre2.… not
          # found` when using e.g. --grep with journalctl. Those errors should
          # become less unexpected now.
          #
          # There are generally two classes of dlopen(3) calls. Those that we want
          # to support and those that should be deactivated / unsupported. This
          # change enforces that we handle all dlopen calls explicitly. Meaning:
          # There is not a single dlopen call in the source code tree that we did
          # not explicitly handle.
          #
          # In order to do this we introduced a list of attributes that maps from
          # shared object name to the package that contains them. The package can be
          # null meaning the reference should be nuked and the shared object will
          # never be loadable during runtime (because it points at an invalid store
          # path location).
          #
          # To get a list of dynamically loaded libraries issue something like
          #   `grep -ri '"lib[a-zA-Z0-9-]*\.so[\.0-9a-zA-z]*"'' $src`
          # and update the list below.
          dlopenLibs =
            let
              opt = condition: pkg: if condition then pkg else null;
            in
            with pkgs; [
              # bpf compilation support. We use libbpf 1 now.
              { name = "libbpf.so.1"; pkg = libbpf; }
              { name = "libbpf.so.0"; pkg = null; }

              # We did never provide support for libxkbcommon
              { name = "libxkbcommon.so.0"; pkg = null; }

              # qrencode
              { name = "libqrencode.so.4"; pkg = qrencode; }
              { name = "libqrencode.so.3"; pkg = null; }

              # Password quality
              # We currently do not package passwdqc, only libpwquality.
              { name = "libpwquality.so.1"; pkg = libpwquality; }
              { name = "libpasswdqc.so.1"; pkg = null; }

              # Only include cryptsetup if it is enabled. We might not be able to
              # provide it during "bootstrap" in e.g. the minimal systemd build as
              # cryptsetup has udev (aka systemd) in it's dependencies.
              { name = "libcryptsetup.so.12"; pkg = cryptsetup; }

              # We are using libidn2 so we only provide that and ignore the others.
              # Systemd does this decision during configure time and uses ifdef's to
              # enable specific branches. We can safely ignore (nuke) the libidn "v1"
              # libraries.
              { name = "libidn2.so.0"; pkg = libidn2; }
              { name = "libidn.so.12"; pkg = null; }
              { name = "libidn.so.11"; pkg = null; }

              # journalctl --grep requires libpcre so let's provide it
              { name = "libpcre2-8.so.0"; pkg = pcre2; }

              # Support for TPM2 in systemd-cryptsetup, systemd-repart and systemd-cryptenroll
              { name = "libtss2-esys.so.0"; pkg = tpm2-tss; }
              { name = "libtss2-rc.so.0"; pkg = tpm2-tss; }
              { name = "libtss2-mu.so.0"; pkg = tpm2-tss; }
              { name = "libtss2-tcti-"; pkg = tpm2-tss; }
              { name = "libfido2.so.1"; pkg = libfido2; }

              # inspect-elf support
              { name = "libelf.so.1"; pkg = elfutils; }
              { name = "libdw.so.1"; pkg = elfutils; }

              # Support for PKCS#11 in systemd-cryptsetup, systemd-cryptenroll and systemd-homed
              { name = "libp11-kit.so.0"; pkg = p11-kit; }

              { name = "libip4tc.so.2"; pkg = iptables; }
              
              # New ones
              { name = "liblzma.so.5"; pkg = xz; }
              { name = "liblz4.so.1"; pkg = lz4; }
              { name = "libzstd.so.1"; pkg = zstd; }
              { name = "libgcrypt.so.20"; pkg = libgcrypt; }
              { name = "libarchive.so.13"; pkg = libarchive; }
              { name = "libkmod.so.2"; pkg = kmod; }
            ];

          patchDlOpen = dl:
            let
              library = "${lib.makeLibraryPath [ dl.pkg ]}/${dl.name}";
            in
            if dl.pkg == null then ''
              # remove the dependency on the library by replacing it with an invalid path
              for file in $(grep -lr '"${dl.name}"' src); do
                echo "patching dlopen(\"${dl.name}\", …) in $file to an invalid store path ("${builtins.storeDir}/eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee-not-implemented/${dl.name}")…"
                substituteInPlace "$file" --replace '"${dl.name}"' '"${builtins.storeDir}/eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee-not-implemented/${dl.name}"'
              done
            '' else ''
              # ensure that the library we provide actually exists
              if ! [ -e ${library} ]; then
                # exceptional case, details:
                # https://github.com/systemd/systemd-stable/blob/v249-stable/src/shared/tpm2-util.c#L157
                if ! [[ "${library}" =~ .*libtss2-tcti-$ ]]; then
                  echo 'The shared library `${library}` does not exist but was given as substitute for `${dl.name}`'
                  exit 1
                fi
              fi
              # make the path to the dependency explicit
              for file in $(grep -lr '"${dl.name}"' src); do
                echo "patching dlopen(\"${dl.name}\", …) in $file to ${library}…"
                substituteInPlace "$file" --replace '"${dl.name}"' '"${library}"'
              done

            '';
        in
        # patch all the dlopen calls to contain absolute paths to the libraries
        lib.concatMapStringsSep "\n" patchDlOpen dlopenLibs
      )
      # finally ensure that there are no left-over dlopen calls (or rather strings
      # pointing to shared libraries) that we didn't handle
      + ''
        if grep -qr '"lib[a-zA-Z0-9-]*\.so[\.0-9a-zA-z]*"' src; then
          echo "Found unhandled dynamic library calls: "
          grep -r '"lib[a-zA-Z0-9-]*\.so[\.0-9a-zA-z]*"' src
          exit 1
        fi
      ''
      # Finally, patch shebangs in scripts used at build time. This must not patch
      # scripts that will end up in the output, to avoid build platform references
      # when cross-compiling.
      + ''
        shopt -s extglob
        patchShebangs tools test src/!(rpm|kernel-install|ukify) src/kernel-install/test-kernel-install.sh
      '';
      buildInputs = finalAttrs.buildInputs ++ [ pkgs.libarchive ];
      mesonFlags = finalAttrs.mesonFlags ++ [ (lib.mesonOption "sysconfdir" "${placeholder "out"}/etc") ];
    }));
  };
}