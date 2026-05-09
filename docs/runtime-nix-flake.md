# Running the Nix Flake

> JYC this is forgotten, this is how you'd normally deploy some of these
flakes to remote stations

```sh
nix shell nixpkgs#nixos-rebuild \
    --command nixos-rebuild switch \
    --flake .#rp-nixos-01 \
    --target-host admin@192.168.178.70 \
    --build-host admin@192.168.178.70 \
    --no-reexec \
    --sudo
```
