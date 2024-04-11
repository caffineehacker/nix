# TPM for unlocking LUKS
#
# TPM kernel module must be enabled for initrd. Device driver is viewable via the command:
# sudo systemd-cryptenroll --tpm2-device=list
# And added to a device's configuration:
# boot.initrd.kernelModules = [ "tpm_tis" ];
#
# Must be enabled by hand - e.g.
# sudo systemd-cryptenroll --wipe-slot=tpm2 /dev/nvme0n1p3 --tpm2-device=auto --tpm2-pcrs=0+2+7
#
{
  lib,
  pkgs,
  config,
  ...
}:
let
  cfg = config.system.tpm-unlock;
in {
  options = {
    system.tpm-unlock.enable = lib.mkOption {
      default = false;
      example = true;
      description = ''
        Enable unlocking encrypted drive with key stored in TPM. Requires secure boot to work.
      '';
      type = lib.types.bool;
    };
  };

  config = lib.mkIf cfg.enable {
    boot.initrd.kernelModules = [ "tpm_tis" ];

    security.tpm2.enable = true;
    security.tpm2.tctiEnvironment.enable = true;
  };
}