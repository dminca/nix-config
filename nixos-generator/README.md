# NixOS generator

> Automate the shit out of Proxmox NixOS VMs creation

## Project structure

```
nixos-generator/
├── flake.nix                          ← image build targets + nixosConfigurations
├── deploy.sh                          ← build → upload → qmrestore in one command
├── modules/
│   └── base.nix                       ← SSH, firewall, admin user, base packages
└── hosts/
    ├── webserver/configuration.nix    ← nginx, static IP 192.168.1.10
    └── dbserver/configuration.nix     ← postgres, static IP 192.168.1.11
```

## Workflow

```sh
# First time — lock inputs
nix flake update

# Build + deploy one VM to your Proxmox node
./deploy.sh webserver root@proxmox-ip 100

# Or build locally and inspect
nix build .#webserver       # → result-webserver/*.vma.zst
nix build .#webserver-qcow2 # → result-webserver-qcow2/*.qcow2

# Iterate on config without rebuilding the image
nixos-rebuild dry-run --flake .#webserver
```

**nixos-anywhere vs. baked images**

`nixos-anywhere` SSHes into a booted target (a live installer, a rescue system, another Linux) and wipes/installs your NixOS config onto it. You end up with a fully managed NixOS system, but the installation step still requires network access and a running target. It's great for bare-metal or when you want to re-provision an existing VM. It's the wrong tool here.

For Proxmox at scale without cloud-init, the right approach is **pre-built disk images**: your Nix flake produces a `qcow2` or a `.vma.zst` (Proxmox VZDump archive) that already *is* the fully installed system — no installer runs at boot, no cloud-init, no SSH bootstrapping. You import it into Proxmox as a template and clone it. Each VM definition lives in your flake; changing config means rebuilding the image and re-importing.

The tool for this is **nixos-generators**, which wraps nixpkgs's image-building infrastructure and has a first-class `proxmox` format that emits a `.vma.zst` Proxmox can restore directly as a VM, plus a `qcow` format for raw disk import.

## FAQ

| Question | Answer |
|---|---|
| Does nixos-anywhere end up with a flake-managed NixOS? | Yes — but it installs *over a running machine* via SSH. It's for bare-metal or when you already have a VM booted with an installer. After install, the VM's `/etc/nixos` is your flake. |
| Better approach for Proxmox at scale, no cloud-init | **Pre-built images via nixos-generators.** Each host config produces a `.vma.zst`. You restore it into Proxmox — the VM boots directly into your fully configured NixOS, no installer runs. |
| Scaling to more VMs | Add a new entry to the hosts attrset in flake.nix, create `hosts/<name>/configuration.nix`, run `.deploy.sh <name> ...`. Each image encodes its hostname, static IP, and services. Nothing dynamic at boot time. |

## Prerequisites before building

1. Add your SSH public key in base.nix under `openssh.authorizedKeys.keys`
2. Adjust IP addresses in each host's `configuration.nix`
3. The build must run on Linux (or a Linux builder) since it's targeting `x86_64-linux` — on macOS use `nix build` with a remote builder or a NixOS VM with `--builders`

----

1. **Remove `nixos-generators`** entirely — it's archived and upstreamed. Use `nixosConfiguration.config.system.build.images.<variant>` from native nixpkgs instead.
2. **Fix `virtualisation.diskSize`** — the old `proxmox.qemuConf.diskSize` option was renamed; set the new name explicitly in `base.nix`. 

**Warning 1 — `proxmox.qemuConf.diskSize`:**  
This was a rename shim inside nixos-generators' proxmox module. It's gone because we no longer use nixos-generators. Additionally, base.nix now explicitly sets `virtualisation.diskSize = 8192` (the canonical, non-deprecated option), so it's clear and overridable per-host.

**Warning 2 — nixos-generators deprecated:**  
flake.nix now drops the `nixos-generators` input entirely. Instead, each host is evaluated once via `nixpkgs.lib.nixosSystem` and the images are accessed via `config.system.build.images.<variant>` — the native interface that nixos-generators' functionality was merged into as of NixOS 25.05. The same system evaluation is reused for both `packages` and `nixosConfigurations`, so nothing is built twice.

**What stays the same:**
```bash
nix build .#webserver          # → .vma.zst
nix build .#webserver-qcow2   # → .qcow2
nix build .#webserver-iso     # → .iso

# Or the new built-in equivalent (no need for nix build at all):
nixos-rebuild build-image --image-variant proxmox --flake .#webserver
```

Run `nix flake update` after this — the lock file still has a `nixos-generators` entry that can be removed with a fresh lock.
