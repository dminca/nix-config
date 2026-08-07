# https://just.systems

nh := require("nh")
nix := require("nix")

default:
  @just --choose

_deploy-nixos host ip:
    {{nh}} os switch \
    --elevation-strategy passwordless .#{{host}} \
    --hostname {{host}} \
    --target-host admin@{{ip}} \
    --build-host admin@{{ip}}

nc: (_deploy-nixos "nc-nixos-01" "10.10.10.156")
kc: (_deploy-nixos "kc-nixos-01" "10.10.10.118")
lw: (_deploy-nixos "lw-nixos-01" "10.10.10.153")
ic: (_deploy-nixos "ic-nixos-01" "10.10.10.162")
rp: (_deploy-nixos "rp-nixos-01" "10.10.10.135")
mon: (_deploy-nixos "mon-nixos-01" "10.10.10.187")

_deploy-macos target:
    {{nh}} darwin switch .#{{target}}
    {{nh}} home switch . --configuration {{target}}

_target_macos := if `hostname` == "Zions-MacBook-Pro.local" { "ZionProxy" } else if `hostname` == "MLGERHL6W4P2RXH" { "MLGERHL6W4P2RXH" } else { error("Unknown hostname: " + `hostname`) }

macos: (_deploy-macos _target_macos)

update:
    {{nix}} flake update
