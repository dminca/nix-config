![logo](https://files.mastodon.social/media_attachments/files/112/151/054/369/403/173/original/a69d68a35ca9d4da.jpeg)

# nix-config
NixOS configuration for bootstrapping Daniel's station (Darwin)

## Description
At the current point in time, this configuration is aimed at aarch64-darwin architecture (Apple Silicon)

## Installation

### Install `nix`

- [&nearr;&nbsp;NixOS docs][1]

```sh
sh <(curl -L https://nixos.org/nix/install) --daemon
```
### Install `nix-darwin`

- [&nearr;&nbsp;nix-darwin][2]

```sh
nix-build https://github.com/LnL7/nix-darwin/archive/master.tar.gz -A installer
./result/bin/darwin-installer
```

### Install `home-manager`

- [&nearr;&nbsp;home-manager][3]

```sh
nix-channel --add https://github.com/nix-community/home-manager/archive/master.tar.gz home-manager
nix-channel --update
```

## Usage

```sh
# with the repo cloned and available locally
darwin-rebuild switch --flake ~/Projects/codeberg.org/dminca/nix-config/

# remote bootstrap
nix run nix-darwin -- switch --flake git+https://codeberg.org/dminca/nix-config.git

# home-manager bootstrap
home-manager switch -f ~/Projects/codeberg.org/dminca/nix-config/home.nix

# run the flake and activate
nix run . -- switch --flake .
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

## Roadmap
- [ ] port all brew packages (all packages are listed in [Brewfile](./Brewfile)
- [x] port dotfiles (zshrc, neovim etc.)
- [x] install `kubectl` for user profile
- [x] install `helm` for user profile
- [x] install `kubectx` for user profile

[1]: https://nixos.org/download
[2]: https://github.com/LnL7/nix-darwin
[3]: https://github.com/nix-community/home-manager
[4]: https://github.com/Mic92/sops-nix

