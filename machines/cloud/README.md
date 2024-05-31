This configuration is for a free tier cloud server hosted on Oracle. The initial setup is done by folowing the instructions at https://blog.korfuri.fr/posts/2022/08/nixos-on-an-oracle-free-tier-ampere-machine/. A brief summary of the commands are below:

```
ssh ubuntu@<server_ip>
# On the server run:
sh <(curl -L https://nixos.org/nix/install) --daemon  # this will prompt you for a few choices, answer n, y, y
git clone https://github.com/cleverca22/nix-tests.git
cd nix-tests/kexec
vim myconfig.nix
```

Populate myconfig.nix with:

```
{
  imports = [
    ./configuration.nix
  ];

  # Make it use predictable interface names starting with eth0
  boot.kernelParams = [ "net.ifnames=0" ];

  networking.useDHCP = true;

  kexec.autoReboot = false;

  users.users.root.openssh.authorizedKeys.keys = [
    <PUT SSH PUB KEYS HERE>
  ];
}
```

Then run

```
nix-build '<nixpkgs/nixos>' -A config.system.build.kexec_tarball -I nixos-config=./myconfig.nix
tar -xf ./result/tarball/nixos-system-aarch64-linux.tar.xz
sudo ./kexec_nixos
```

The connection will be terminated after a few minutes when it prints `+ kexec -e` (not `+ kexec -l`). Just press enter to be disconnected. Now drop the server key and reconnect. Note that we now reconnect as root, not ubuntu.

```
ssh-keygen -R <server_ip>
ssh root@<server_ip>
```

Now use `parted` to delete all partitions and then create a boot partition with

```
(parted) rm 1
(parted) rm 15
(parted) mkpart
Partition name?  []? boot
File system type?  [ext2]? fat32
Start? 2048s
End? 2GB
(parted) set 1 boot on
(parted) set 1 esp on
(parted) mkpart
Partition name?  []?
File system type?  [ext2]? ext4
Start? 2GB
End? -1s
(parted) quit
```

Now create the partitions and mount

```
mkfs.fat -F 32 /dev/sda1
mkfs.ext4 /dev/sda2
mount /dev/sda2 /mnt/
mkdir -p /mnt/boot
mount /dev/sda1 /mnt/boot/
nixos-generate-config --root /mnt
vim /mnt/etc/nixos/configuration.nix   # You want to at least set openssh.enable = true; and add an ssh key for root, like we did in the temporary system above.
nixos-install
```

Once done you can disconnect, drop the host key again, and reconnect:

```
ssh-keygen -R <server_ip>
ssh root@<server_ip>
```

Now you can deploy this configuration by running the update-cloud script
