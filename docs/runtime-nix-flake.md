# Deploy a Nix Flake to a Remote Host

Diataxis type: How-to guide

Use this command pattern to build and switch a remote NixOS host directly from your local flake.

## Command

```sh
nix shell nixpkgs#nixos-rebuild \
    --command nixos-rebuild switch \
    --flake .#rp-nixos-01 \
    --target-host admin@192.168.178.70 \
    --build-host admin@192.168.178.70 \
    --no-reexec \
    --sudo
```

## Adjust for your environment

- Replace `.#rp-nixos-01` with your target flake output.
- Replace `admin@192.168.178.70` with the correct SSH user and host.
- If running from Darwin/non-Linux, include options required by your environment, such as `--fast`.
