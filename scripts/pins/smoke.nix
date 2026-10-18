# Natively fetch every `*.pin.json` source (all platforms' assets) and build the
# ./pkgs packages for this system. caddy-plugin pins can only be verified on
# their host's system; `unverified` lists the ones skipped here.
# Run via `just smoke`; needs --impure for getFlake/currentSystem.
{ root }:
let
  flake = builtins.getFlake root;
  system = builtins.currentSystem;
  pkgs = flake.inputs.nixpkgs.legacyPackages.${system};
  inherit (pkgs) lib;

  pinFiles = lib.filter (lib.hasSuffix ".pin.json") (lib.filesystem.listFilesRecursive flake.outPath);
  sources =
    p:
    {
      github-release = lib.mapAttrsToList (_: a: pkgs.fetchurl { inherit (a) url hash; }) p.assets;
      github-commit = [
        (pkgs.fetchFromGitHub {
          inherit (p)
            owner
            repo
            rev
            hash
            ;
        })
      ];
      amo = [ (pkgs.fetchurl { inherit (p) url hash; }) ];
      vscode-marketplace = [
        (pkgs.vscode-utils.fetchVsixFromVscodeMarketplace {
          inherit (p)
            name
            publisher
            version
            hash
            ;
        })
      ];
      caddy-plugin =
        let
          hostSystem = flake.nixosConfigurations.${p.host}.pkgs.stdenv.hostPlatform.system;
        in
        if hostSystem == system then
          [
            (import ./caddy-src.nix {
              inherit root;
              inherit (p) host hash;
              plugin = "${p.module}@${p.version}";
            })
          ]
        else
          lib.warn
            "smoke: NOT verifying caddy-plugin ${p.module} hash (needs ${hostSystem}, this is ${system})"
            [ ];
    }
    .${p.kind} or (throw "smoke: unsupported pin kind ${p.kind}");

  packages = lib.filter (lib.meta.availableOn pkgs.stdenv.hostPlatform) (
    map (n: pkgs.callPackage (flake.outPath + "/pkgs/${n}") { }) (
      lib.attrNames (
        lib.filterAttrs (_: t: t == "directory") (builtins.readDir (flake.outPath + "/pkgs"))
      )
    )
  );
  unverified = map (f: lib.removeSuffix ".pin.json" (baseNameOf f)) (
    lib.filter (
      f:
      let
        p = lib.importJSON f;
      in
      p.kind == "caddy-plugin"
      && flake.nixosConfigurations.${p.host}.pkgs.stdenv.hostPlatform.system != system
    ) pinFiles
  );
in
(pkgs.linkFarm "pin-smoke" (
  lib.imap0 (i: drv: {
    name = "${toString i}-${drv.name}";
    path = drv;
  }) (lib.concatMap (f: sources (lib.importJSON f)) pinFiles ++ packages)
))
// {
  inherit unverified;
}
