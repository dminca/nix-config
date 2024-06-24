![logo](https://files.mastodon.social/media_attachments/files/112/151/054/369/403/173/original/a69d68a35ca9d4da.jpeg)

[![built with nix](https://img.shields.io/static/v1?logo=nixos&logoColor=white&label=&message=Built%20with%20Nix&color=41439a)](https://builtwithnix.org)

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

### Installing fonts

It's just not straightforward. This case covers only fonts installed via
`Home-Manager`

After `nix run -- switch --flake .` this needs to be executed

```sh
# reload font cache
fc-cache
```

```sh
# check font was installed; in this case 'Hack' (part of nerdfonts family)
fc-list -v | grep -i 'hack'
```

Should retrieve a list of garbled stuff referencing 'Hack' in there.

More info [&nearr;&nbsp;here][5].

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
[5]: https://nixos.wiki/wiki/Fonts

