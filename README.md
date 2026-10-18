![logo](https://files.mastodon.social/media_attachments/files/112/151/054/369/403/173/original/a69d68a35ca9d4da.jpeg)

[![built with nix](https://img.shields.io/static/v1?logo=nixos&logoColor=white&label=&message=Built%20with%20Nix&color=41439a)](https://builtwithnix.org)

# nix-config
NixOS configuration for bootstrapping Daniel's station (Darwin)

> [!CAUTION]
> This hosts system and home configurations are public for your own learning and
> research. They are not meant to be used with any hardware other than mine.
> Trying to build and deploy them to other systems without appropriate changes
> can render your machines unbootable and damage data.

## Description
This repository contains both:
- nix-darwin + Home Manager profiles for aarch64-darwin (Apple Silicon)
- NixOS host profiles for x86_64-linux systems

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
    --no-reexec \
    --sudo
```

> [!NOTE]  
> Required to pass `--fast` and `--target-host user@host` if execution is triggered
> from a Darwin or non-linux workstation.

### Installing `hephaestus` from macOS with `nixos-anywhere`

Use the dedicated template in [`./hephaestus`](./hephaestus) and run the command shown in its README.

### Installing `rss-nixos-01` with `nixos-anywhere`

Use the dedicated template in [`./rss-nixos-01`](./rss-nixos-01) and run the command shown in its README.

### Bumping pinned sources and smoke testing

Hand-pinned sources (release assets, Firefox/VS Code extensions, commit pins,
the Caddy plugin) live in `<name>.pin.json` files next to the Nix file that
reads them with `lib.importJSON`. A small Go tool (`scripts/pins`, run inside
`nix develop`) bumps them; it only rewrites those JSON files. Flake inputs are
separate: `just update` runs `nix flake update`.

```sh
just pins                      # list pins
GITHUB_TOKEN=$(gh auth token) just pins-check   # report newer releases/commits (read-only)
just pins-update [NAME...]     # bump version/rev/url/hash (all or NAMEs)
just pins-test                 # offline Go tests of the updater
just smoke                     # eval every host; fetch every pin natively; build ./pkgs
just smoke-build HOST          # build HOST's full config (no activation); HOST must match this machine
```

- Releases follow the newest stable release, or the newest prerelease when the
  pin has `"prerelease": true`; commit pins follow their `branch` head.
- `GITHUB_TOKEN` is optional for `pins-check` and `pins-update` (both call the
  GitHub API; unauthenticated limit is 60 requests/hour). Set it inline as above;
  never echo it.
- `just smoke` needs flakes, network access to GitHub, AMO and the VS Code
  Marketplace, and new `*.pin.json` files `git add`ed. It proves evaluation and
  that pinned hashes/./pkgs build on this machine, and ends by naming any pin it
  could not verify here; only `just smoke-build HOST` proves a host builds.
- `caddy-plugin` hashes can only be computed/verified on the host's system
  (x86_64-linux), e.g. `just pins-update caddy-desec` on hephaestus.
- To add a pin: create `<name>.pin.json` with an existing `kind` (see
  `scripts/pins/main.go`), read it with `lib.importJSON`, then run
  `just pins-check NAME` and `just smoke`.

## Roadmap [completed] 🎉
- [x] port all brew packages (all packages are listed in [Brewfile](./Brewfile)
- [x] port dotfiles (zshrc, neovim etc.)
- [x] install `kubectl` for user profile
- [x] install `helm` for user profile
- [x] install `kubectx` for user profile

[1]: https://docs.determinate.systems/getting-started/individuals/
[2]: https://github.com/LnL7/nix-darwin
[4]: https://github.com/Mic92/sops-nix
