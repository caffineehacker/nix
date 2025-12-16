To generate wireguard keys, run the following command:

```
nix-shell -p wireguard-tools --run "wg genkey | tee privatekey | wg pubkey > publickey"
```

Then open the sops secrets and add the private and public keys:

```
sops secrets/secrets.yaml
```