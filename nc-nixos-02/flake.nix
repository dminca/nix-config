{
  description = "Pre-baked NixOS VM images for Proxmox";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
  };

  outputs =
    { self, nixpkgs }:
    let
      system = "x86_64-linux";

      # ── host registry ────────────────────────────────────────────────────
      # Add one entry per VM.  Each value is the NixOS module list for that host.
      hosts = {
        nc-nixos-02 = [
          ./modules/base.nix
        ];
      };

      # Evaluate each host once; reuse the result for both packages and
      # nixosConfigurations so the system closure is only built once per host.
      nixosSystems = builtins.mapAttrs (
        _: modules: nixpkgs.lib.nixosSystem { inherit system modules; }
      ) hosts;

      allPackages =
        # nix build .#tst-nixos-02          → .vma.zst
        (builtins.mapAttrs (name: sys: sys.config.system.build.images.proxmox) nixosSystems)
        # nix build .#tst-nixos-02-qemu   → .qemu
        // builtins.listToAttrs (
          map (name: {
            name = "${name}-qemu";
            value = nixosSystems.${name}.config.system.build.images.qemu;
          }) (builtins.attrNames hosts)
        )
        # nix build .#tst-nixos-02-plxc   → .lxc
        // builtins.listToAttrs (
          map (name: {
            name = "${name}-plxc";
            value = nixosSystems.${name}.config.system.build.images.proxmox-lxc;
          }) (builtins.attrNames hosts)
        )
        # nix build .#tst-nixos-02-iso     → .iso  (live/ephemeral)
        // builtins.listToAttrs (
          map (name: {
            name = "${name}-iso";
            value = nixosSystems.${name}.config.system.build.images.iso;
          }) (builtins.attrNames hosts)
        );

    in
    {

      # nix build .#tst-nixos-02          → .vma.zst  (persistent, Proxmox VZDump restore)
      # nix build .#tst-nixos-02-qcow2   → .qcow2    (persistent, disk import)
      # nix build .#tst-nixos-02-iso     → .iso      (live/ephemeral, boot from CD-ROM)
      #
      # Or use the built-in command (no nix build needed, works on any nixosConfiguration):
      #   nixos-rebuild build-image --image-variant proxmox --flake .#tst-nixos-02
      packages.${system} = allPackages;

      # nixos-rebuild switch --flake .#tst-nixos-02  (iterate config without rebuilding image)
      nixosConfigurations = nixosSystems;

    };
}
