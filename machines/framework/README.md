# Setup

1. Disable secure boot
1. Partition the machine with a /boot partition of type fat32 and the rest of the disk as a single partition of type 8300 (Linux LVM).
1. Run `cryptsetup luksFormat /dev/disk....`
1. Run `cryptsetup luksOpen /dev/disk.... enc-pv`
1. To create the logical volume run `pvcreate /dev/mapper/enc-pv`
1. Run `vgcreate vg /dev/mapper/enc-pv`
1. Create the swap partition `lvcreate -L 100G -n swap vg`
1. Create root partition `lvcreate -l '100%FREE' -n root vg`
1. Format boot `mkfs.fat /dev/disk...p0`
1. Format root `mkfs.ext4 -L root /dev/vg/root`
1. Format swap `mkswap -L swap /dev/vg/swap`
1. Follow the rest of the Nix OS install guide making sure to mount with the UUIDs
1. Reset / clear the secure boot keys in the bios
1. Run `systemd-cryptenroll --tpm2-device=auto --tpm2-pcrs=7 /dev/your_encrypted_partition` to enable automatic unlock from the TPM
1. Run `sudo sbctl create-keys`
1. Run `sudo sbctl enroll-keys`
1. Reboot and enable secure boot in the bios
1. Now you should be able to boot without typing in the drive password
1. Run `sudo fprintd-enroll <user>` to configure a fingerprint for better login

# Notes

This config builds everything from scratch, but will likely fail on first run due to the system-features not having taken effect. The fix is to remove the `nixpkgs.hostPlatform.gcc.*` settings and do one rebuild switch (with the system-features setting still set). Then you can restore the gcc settings and do another rebuild switch.