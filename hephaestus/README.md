# hephaestus nixos-anywhere template

This is the dedicated bootstrap template used only for initial remote install/partitioning of the Lenovo workstation.

## Usage

Run from the nixos-anywhere host template directory:

```sh
cd hephaestus
nix run nixpkgs#nixos-anywhere -- \
  --flake .#hephaestus \
  --target-host <installer-user>@<installer-ip> \
  -i <ssh-private-key> \
  --build-on remote \
  --generate-hardware-config nixos-generate-config ./hardware-configuration.nix \
  --disk main /dev/disk/by-id/<your-nvme-id>
```

After first install succeeds, use the main repo host profile at `hosts/hephaestus`.
