# https://just.systems

nh := require("nh")
hostname := shell("sh", "-c", "scutil --get LocalHostName 2>/dev/null || hostname -s")

default:
  @just --choose

darwinRebuild host=hostname:
    {{nh}} darwin switch \
        .#{{host}}

    {{nh}} home switch \
        .#{{host}}

nc:
    {{nh}} os switch \
    --elevation-strategy passwordless .#nc-nixos-01 \
    --hostname nc-nixos-01 \
    --target-host admin@10.10.10.156 \
    --build-host admin@10.10.10.156

kc:
    {{nh}} os switch \
    --elevation-strategy passwordless .#kc-nixos-01 \
    --hostname kc-nixos-01 \
    --target-host admin@10.10.10.118 \
    --build-host admin@10.10.10.118

lw:
    {{nh}} os switch \
    --elevation-strategy passwordless .#lw-nixos-01 \
    --hostname lw-nixos-01 \
    --target-host admin@10.10.10.153 \
    --build-host admin@10.10.10.153

ic:
    {{nh}} os switch \
    --elevation-strategy passwordless .#ic-nixos-01 \
    --hostname ic-nixos-01 \
    --target-host admin@10.10.10.162 \
    --build-host admin@10.10.10.162

rp:
    {{nh}} os switch \
    --elevation-strategy passwordless .#rp-nixos-01 \
    --hostname rp-nixos-01 \
    --target-host admin@10.10.10.135 \
    --build-host admin@10.10.10.135

mon:
    {{nh}} os switch \
    --elevation-strategy passwordless .#mon-nixos-01 \
    --hostname mon-nixos-01 \
    --target-host admin@10.10.10.187 \
    --build-host admin@10.10.10.187

pmac:
    just darwinRebuild ZionProxy

wmac:
    just darwinRebuild MLGERHL6W4P2RXH
