![logo](https://files.mastodon.social/media_attachments/files/112/151/054/369/403/173/original/a69d68a35ca9d4da.jpeg)

[![built with nix](https://img.shields.io/static/v1?logo=nixos&logoColor=white&label=&message=Built%20with%20Nix&color=41439a)](https://builtwithnix.org)

# nix-config
NixOS configuration for bootstrapping Daniel's station (Darwin).

> [!CAUTION]
> This hosts system and home configurations are public for your own learning and
> research. They are not meant to be used with any hardware other than mine.
> Trying to build and deploy them to other systems without appropriate changes
> can render your machines unbootable and damage data.

## Diataxis Documentation

This README is organized using the Diataxis framework:

- Tutorial: learn by doing a first successful activation.
- How-to guides: solve specific operational tasks.
- Reference: quick command and environment lookup.
- Explanation: understand design choices and constraints.

## Tutorial

### Get your first successful activation on Darwin

This tutorial is for first-time users who want a working local activation of this flake on Apple Silicon.

Prerequisites:

- macOS on Apple Silicon (`aarch64-darwin` target).
- Administrative access on your machine.
- Git installed.

Step 1. Install Nix (Determinate Systems installer):

1. Follow the Determinate Systems installation guide [from Determinate Systems][1].

Step 2. Verify Nix is available:

```sh
nix --version
```

Step 3. Clone this repository and move into it:

```sh
git clone https://github.com/dminca/nix-config.git
cd nix-config
```

Step 4. Run local activation:

```sh
nix run .
```

Step 5. Confirm the command completed without errors and your expected Home Manager changes are present.

What you achieved:

- Installed and validated Nix.
- Executed the flake locally.
- Reached a reproducible baseline for further customization.

## How-to Guides

### Activate configuration from GitHub (remote source)

Use this when you do not want to clone the repository first.

```sh
nix run github:dminca/nix-config
```

### Activate configuration from a local clone

Use this when working on local changes.

```sh
nix run .
```

### Manage secrets with `sops-nix`

#### Create and encrypt secrets (day 1 setup)

Sample `.sops.yaml` and `secrets/example.yaml` are based on [sops-nix examples][4].

1. Create the key directory:

```sh
mkdir -vp ~/.config/sops/age
```

2. Generate an age key:

```sh
nix-shell -p age --run "age-keygen -o ~/.config/sops/age/keys.txt"
```

3. Create plaintext secret content:

```sh
vi secrets/example.yaml
```

4. Ensure `.sops.yaml` recipients/rules are configured.

5. Encrypt the file:

```sh
nix-shell -p sops --run "sops --encrypt secrets/example.yaml" | pbcopy
```

#### Edit encrypted secrets later (day 2 workflow)

```sh
nix-shell -p sops --run "sops secrets/example.yaml"
```

### Find plugin packages for Home Manager

Use these commands to search package names you can place in a Home Manager `plugins = []` list.

> [!IMPORTANT]
> Plugin commands below were tested in Home Manager workflows.

```sh
nix-env -f '<nixpkgs>' -qaP -A vimPlugins
```

```sh
nix-env -f '<nixpkgs>' -qaP -A tmuxPlugins
```

### Build a NixOS host remotely

Use this from a workstation to build and switch a remote NixOS target.

```sh
nix shell nixpkgs#nixos-rebuild \
    --command nixos-rebuild switch \
    --flake .#nixos \
    --target-host dminca@nixos \
    --build-host dminca@nixos \
    --no-reexec \
    --sudo
```

> [!NOTE]
> When triggered from Darwin or another non-Linux workstation, include `--fast` and `--target-host user@host` as required by your environment.

## Reference

### Supported platform

- Primary target: `aarch64-darwin` (Apple Silicon).

### Core activation commands

```sh
# remote activation
nix run github:dminca/nix-config

# local activation
nix run .
```

### Secret management commands

```sh
# generate age key
nix-shell -p age --run "age-keygen -o ~/.config/sops/age/keys.txt"

# encrypt secret file
nix-shell -p sops --run "sops --encrypt secrets/example.yaml"

# edit encrypted secret file
nix-shell -p sops --run "sops secrets/example.yaml"
```

### Plugin discovery commands

```sh
nix-env -f '<nixpkgs>' -qaP -A vimPlugins
nix-env -f '<nixpkgs>' -qaP -A tmuxPlugins
```

### Remote host build command

```sh
nix shell nixpkgs#nixos-rebuild \
    --command nixos-rebuild switch \
    --flake .#nixos \
    --target-host dminca@nixos \
    --build-host dminca@nixos \
    --no-reexec \
    --sudo
```

### External links

- Nix installer: [Determinate Systems guide][1]
- nix-darwin project: [LnL7/nix-darwin][2]
- secrets tooling: [Mic92/sops-nix][4]

## Explanation

### Why this repository is public but not generally reusable

This configuration captures one real workstation/server fleet and includes host-specific assumptions (hardware, topology, service composition, and operational preferences). Publishing it helps others learn patterns, but applying it unchanged to another machine is unsafe.

### Why the docs separate Darwin activation from NixOS host deployment

The repository supports both:

- Local Darwin activation for user environment bootstrapping.
- Remote NixOS host build/deploy workflows.

These workflows have different risk profiles and execution contexts, so they are documented separately to reduce operator error.

### Why secrets are handled with `sops-nix`

`sops-nix` keeps encrypted secrets in versioned configuration while allowing controlled decryption on authorized systems. This balances reproducibility and security for declarative infrastructure.

## Status

### Roadmap completed

- [x] Port all brew packages (listed in `Brewfile`).
- [x] Port dotfiles (`zshrc`, `neovim`, and related setup).
- [x] Install `kubectl` in user profile.
- [x] Install `helm` in user profile.
- [x] Install `kubectx` in user profile.

[1]: https://docs.determinate.systems/getting-started/individuals/
[2]: https://github.com/LnL7/nix-darwin
[4]: https://github.com/Mic92/sops-nix
