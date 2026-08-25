# https://just.systems

nh := require("nh")
nix := require("nix")

default:
  @just --choose

_deploy-nixos host ip user='admin':
    {{nh}} os switch \
    .#{{host}} \
    --hostname {{host}} \
    --target-host {{user}}@{{ip}} \
    --build-host {{user}}@{{ip}}

nc: (_deploy-nixos "nc-nixos-01" "10.10.10.156")
kc: (_deploy-nixos "kc-nixos-01" "10.10.10.118")
lw: (_deploy-nixos "lw-nixos-01" "10.10.10.153")
ic: (_deploy-nixos "ic-nixos-01" "10.10.10.162")
rp: (_deploy-nixos "rp-nixos-01" "10.10.10.135")
mon: (_deploy-nixos "mon-nixos-01" "10.10.10.187")
hs: (_deploy-nixos "hs-nixos-01" "10.10.10.157")
hephaestus: (_deploy-nixos "hephaestus" "192.168.178.87" "dminca")
notes: (_deploy-nixos "notes-nixos-01" "10.10.10.173")

_deploy-macos target:
    {{nh}} darwin switch .#{{target}}
    {{nh}} home switch . --configuration {{target}}

_target_macos := if `hostname` == "ZionProxy" { "ZionProxy" } else if `hostname` == "MLGERHL6W4P2RXH" { "MLGERHL6W4P2RXH" } else { error("Unknown hostname: " + `hostname`) }

macos: (_deploy-macos _target_macos)

update:
    {{nix}} flake update
