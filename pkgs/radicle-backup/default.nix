{
  lib,
  stdenv,
  fetchurl,
}:
let
  version = "0.4.0";
  platforms = {
    x86_64-linux = {
      suffix = "x86_64-unknown-linux-musl";
      sha256 = "dbb30cb2682e70d0ff40a8a60f5636818a8e5d483e8e64f582db7da8975cf646";
    };
    aarch64-darwin = {
      suffix = "aarch64-apple-darwin";
      sha256 = "5dae42bd00ace6b2af65b2dd866a3b5d361d7b8c5fbc04dd1d9f2bdd87cc7ab8";
    };
  };
  platform = platforms.${stdenv.hostPlatform.system}
    or (throw "radicle-backup: unsupported system ${stdenv.hostPlatform.system}");
in
stdenv.mkDerivation {
  pname = "radicle-backup";
  inherit version;

  src = fetchurl {
    url = "https://github.com/maninak/radicle-backup/releases/download/v${version}/rad-backup-${platform.suffix}.tar.gz";
    inherit (platform) sha256;
  };

  dontBuild = true;
  dontConfigure = true;

  installPhase = ''
    runHook preInstall
    install -Dm755 rad-backup $out/bin/rad-backup
    ln -s rad-backup $out/bin/rad-restore
    runHook postInstall
  '';

  meta = {
    description = "Back up, restore and move a Radicle identity, node state and repositories";
    homepage = "https://github.com/maninak/radicle-backup";
    license = [ lib.licenses.mit lib.licenses.asl20 ];
    platforms = builtins.attrNames platforms;
    mainProgram = "rad-backup";
  };
}
