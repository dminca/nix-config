![logo](https://files.mastodon.social/media_attachments/files/112/151/054/369/403/173/original/a69d68a35ca9d4da.jpeg)

[![built with nix](https://img.shields.io/static/v1?logo=nixos&logoColor=white&label=&message=Built%20with%20Nix&color=41439a)](https://builtwithnix.org)

# nix-config
NixOS configuration for bootstrapping Daniel's station (Darwin)

## Description
At the current point in time, this configuration is aimed at aarch64-darwin architecture (Apple Silicon)

## Installation

### Install `nix`

1. Just follow this guide [&nearr;&nbsp;from DeterminateSystems][1]

### Install `home-manager`

1. it's already baked into DeterminateSystems Nix installer

## Usage

```sh
# remote activation
nix run github:dminca/nix-config

# local activation
nix run .
```

### Secret management with `sops-nix`

#### Day-1

- sample `.sops.yaml` & `secrets/example.yaml` [&nearr;&nbsp;source][4]

```sh
# create dir where key will be added
mkdir -vp ~/.config/sops/age

# generate key
nix-shell -p age --run "age-keygen -o ~/.config/sops/age/keys.txt"

# prepare data to encrypt
vi secrets/example.yaml

# have .sops.yaml filled

# encrypt data
nix-shell -p sops --run "sops --encrypt secrets/example.yaml" | pbcopy
```

#### Day-2

```sh
# add/remove entries from secrets file
nix-shell -p sops --run "sops secrets/example.yaml"
```

### Searching for `tmux` or `vim` plugins

> [!IMPORTANT]
> These plugins can only be used within `home-manager` setup (it's the only way I tested).
> The search will retrieve a list of packages from the Nix Store, this means
> you can add them in the `plugins = []` section

```sh
nix-env -f '<nixpkgs>' -qaP -A vimPlugins
```

```sh
nix-env -f '<nixpkgs>' -qaP -A tmuxPlugins
```

### Building the NixOS host remotely

To remotely build the NixOS host run

```sh
nix shell nixpkgs#nixos-rebuild \
    --command nixos-rebuild switch \
    --flake .#nixos \
    --target-host dminca@nixos \
    --build-host dminca@nixos \
    --fast \
    --use-remote-sudo
```

> [!NOTE]  
> Required to pass `--fast` and `--target-host user@host` if execution is triggered
> from a Darwin or non-linux workstation.

## Roadmap [completed] 🎉
- [x] port all brew packages (all packages are listed in [Brewfile](./Brewfile)
- [x] port dotfiles (zshrc, neovim etc.)
- [x] install `kubectl` for user profile
- [x] install `helm` for user profile
- [x] install `kubectx` for user profile

[1]: https://docs.determinate.systems/getting-started/individuals/
[2]: https://github.com/LnL7/nix-darwin
[4]: https://github.com/Mic92/sops-nix
