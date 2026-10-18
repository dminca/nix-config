# Vendored Caddy source for `caddy.withPlugins` with nixosConfigurations.<host>'s
# nixpkgs. Built natively only: the hash computed on aarch64-darwin was shown to
# differ from the Linux one, so it must be computed on the host's system.
{
  root,
  host,
  plugin,
  hash ? "",
}:
let
  pkgs = (builtins.getFlake root).nixosConfigurations.${host}.pkgs;
  system = pkgs.stdenv.hostPlatform.system;
in
assert pkgs.lib.assertMsg (
  builtins.currentSystem == system
) "caddy-plugin pins for ${host} must be hashed on ${system}, not ${builtins.currentSystem}";
(pkgs.caddy.withPlugins {
  plugins = [ plugin ];
  hash = if hash == "" then pkgs.lib.fakeHash else hash;
}).src
