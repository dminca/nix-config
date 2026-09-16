# https://just.systems

nh := require("nh")
nix := require("nix")

default:
  @just --choose

_deploy-nixos host ip:
    if [ "`uname -m`" = "x86_64" ] && [ "`uname -s`" = "Linux" ]; then \
    {{nh}} os switch \
    .#{{host}} \
    --hostname {{host}} \
    --elevation-strategy passwordless \
    --target-host admin@{{ip}}; \
    elif { [ "`uname -m`" = "arm64" ] || [ "`uname -m`" = "aarch64" ]; } && [ "`uname -s`" = "Darwin" ]; then \
    {{nh}} os switch \
    .#{{host}} \
    --hostname {{host}} \
    --target-host admin@{{ip}} \
    --build-host admin@{{ip}}; \
    else \
    echo "Unsupported host architecture for _deploy-nixos: `uname -m`-`uname -s`"; \
    exit 1; \
    fi

_deploy-nixos-local host:
    {{nh}} os switch \
    .#{{host}} \
    --hostname {{host}}

nc: (_deploy-nixos "nc-nixos-01" "nc-nixos-01.home.arpa")
kc: (_deploy-nixos "kc-nixos-01" "kc-nixos-01.home.arpa")
lw: (_deploy-nixos "lw-nixos-01" "lw-nixos-01.home.arpa")
ic: (_deploy-nixos "ic-nixos-01" "ic-nixos-01.home.arpa")
rp: (_deploy-nixos "rp-nixos-01" "rp-nixos-01.home.arpa")
mon: (_deploy-nixos "mon-nixos-01" "mon-nixos-01.home.arpa")
hs: (_deploy-nixos "hs-nixos-01" "hs-nixos-01.home.arpa")
hephaestus: (_deploy-nixos "hephaestus" "192.168.178.87")
hephaestus-local: (_deploy-nixos-local "hephaestus")
notes: (_deploy-nixos "notes-nixos-01" "notes-nixos-01.home.arpa")
rss: (_deploy-nixos "rss-nixos-01" "rss-nixos-01.home.arpa")

_deploy-macos target:
    {{nh}} darwin switch .#{{target}}
    {{nh}} home switch . --configuration {{target}}

_target_macos := if `hostname` == "ZionProxy" { "ZionProxy" } else if `hostname` == "MLGERHL6W4P2RXH" { "MLGERHL6W4P2RXH" } else { "" }

macos:
    @if [ -z "{{_target_macos}}" ]; then echo "macos target is only supported on ZionProxy or MLGERHL6W4P2RXH"; exit 1; fi
    @just _deploy-macos "{{_target_macos}}"

update:
    {{nix}} flake update
