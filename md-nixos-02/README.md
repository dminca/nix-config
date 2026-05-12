# nixos-anywhere-examples

Checkout the [flake.nix](flake.nix) for examples tested on different hosters.

## Usage

```sh
nix run nixpkgs#nixos-anywhere -- \
    --flake .#proxmox \
    --generate-hardware-config nixos-generate-config ./hardware-configuration.nix \
    nixos@10.10.10.102
```
