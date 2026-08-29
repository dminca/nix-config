# https://just.systems

nh := require("nh")
nix := require("nix")

default:
  @just --choose

_deploy-nixos host ip user='admin':
    if [ "`uname -m`" = "x86_64" ] && [ "`uname -s`" = "Linux" ]; then \
    {{nh}} os switch \
    .#{{host}} \
    --hostname {{host}} \
    --target-host {{user}}@{{ip}}; \
    elif { [ "`uname -m`" = "arm64" ] || [ "`uname -m`" = "aarch64" ]; } && [ "`uname -s`" = "Darwin" ]; then \
    {{nh}} os switch \
    .#{{host}} \
    --hostname {{host}} \
    --target-host {{user}}@{{ip}} \
    --build-host {{user}}@{{ip}}; \
    else \
    echo "Unsupported host architecture for _deploy-nixos: `uname -m`-`uname -s`"; \
    exit 1; \
    fi

_deploy-nixos-local host:
    {{nh}} os switch \
    .#{{host}} \
    --hostname {{host}}

nc: (_deploy-nixos "nc-nixos-01" "10.10.10.156")
kc: (_deploy-nixos "kc-nixos-01" "10.10.10.118")
lw: (_deploy-nixos "lw-nixos-01" "10.10.10.153")
ic: (_deploy-nixos "ic-nixos-01" "10.10.10.162")
rp: (_deploy-nixos "rp-nixos-01" "10.10.10.135")
mon: (_deploy-nixos "mon-nixos-01" "10.10.10.187")
hs: (_deploy-nixos "hs-nixos-01" "10.10.10.157")
hephaestus: (_deploy-nixos "hephaestus" "192.168.178.87" "dminca")
hephaestus-local: (_deploy-nixos-local "hephaestus")
notes: (_deploy-nixos "notes-nixos-01" "10.10.10.173")

_deploy-macos target:
    {{nh}} darwin switch .#{{target}}
    {{nh}} home switch . --configuration {{target}}

_target_macos := if `hostname` == "ZionProxy" { "ZionProxy" } else if `hostname` == "MLGERHL6W4P2RXH" { "MLGERHL6W4P2RXH" } else { "" }

macos:
    @if [ -z "{{_target_macos}}" ]; then echo "macos target is only supported on ZionProxy or MLGERHL6W4P2RXH"; exit 1; fi
    @just _deploy-macos "{{_target_macos}}"

update:
    {{nix}} flake update
