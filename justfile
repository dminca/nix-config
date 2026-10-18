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
    --elevation-strategy passwordless \
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

upgrade-vms:
    for h in mon rp hs notes rss ic kc nc lw; do just $h; just $h; done

update:
    {{nix}} flake update

# --- Pinned sources: *.pin.json read by Nix via lib.importJSON (flake inputs: `just update`) ---

_pins *args:
    {{nix}} develop --command go -C scripts/pins run . -root "{{justfile_directory()}}" {{args}}

# list every *.pin.json
pins: (_pins "list")

# report pins with a newer upstream release/commit (read-only)
pins-check *names: (_pins "check" names)

# bump version/rev/url/hash of outdated pins (all, or only NAMES)
pins-update *names: (_pins "update" names)

# offline unit tests of the pin updater
pins-test:
    {{nix}} develop --command go -C scripts/pins test ./...

# evaluate every host, then natively fetch every pinned source and build ./pkgs (no host build, no activation)
smoke:
    {{nix}} eval --json .#nixosConfigurations --apply 'builtins.mapAttrs (_: c: c.config.system.build.toplevel.drvPath)'
    {{nix}} eval --json .#darwinConfigurations --apply 'builtins.mapAttrs (_: c: c.system.drvPath)'
    {{nix}} eval --json .#homeConfigurations --apply 'builtins.mapAttrs (_: c: c.activationPackage.drvPath)'
    {{nix}} build --no-link --print-out-paths --impure --file scripts/pins/smoke.nix --argstr root "{{justfile_directory()}}"

# build HOST's whole configuration without activating it; HOST must match this machine's system
smoke-build host:
    #!/usr/bin/env bash
    set -euo pipefail
    native=$({{nix}} eval --impure --raw --expr builtins.currentSystem)
    targets=()
    for out in nixosConfigurations:config.system.build.toplevel darwinConfigurations:system homeConfigurations:activationPackage; do
      set="${out%%:*}" attr="${out#*:}"
      [ "$({{nix}} eval --json ".#$set" --apply 'c: c ? "{{host}}"')" = true ] || continue
      sys=$({{nix}} eval --raw ".#$set.\"{{host}}\".pkgs.stdenv.hostPlatform.system")
      if [ "$sys" != "$native" ]; then
        echo "{{host}} ($set) is $sys but this machine is $native; run smoke-build on a $sys machine" >&2
        exit 1
      fi
      targets+=(".#$set.\"{{host}}\".$attr")
    done
    [ ${#targets[@]} -gt 0 ] || { echo "unknown host {{host}}" >&2; exit 2; }
    {{nix}} build --no-link --print-out-paths "${targets[@]}"
