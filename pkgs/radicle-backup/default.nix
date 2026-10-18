{
  lib,
  stdenv,
  fetchurl,
}:
let
  # Bump with `just pins-update radicle-backup`.
  pin = lib.importJSON ./radicle-backup.pin.json;
  asset =
    pin.assets.${stdenv.hostPlatform.system}
      or (throw "radicle-backup: unsupported system ${stdenv.hostPlatform.system}");
in
stdenv.mkDerivation {
  pname = "radicle-backup";
  inherit (pin) version;

  src = fetchurl { inherit (asset) url hash; };

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
    license = [
      lib.licenses.mit
      lib.licenses.asl20
    ];
    platforms = builtins.attrNames pin.assets;
    mainProgram = "rad-backup";
  };
}
