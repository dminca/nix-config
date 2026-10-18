{
  lib,
  stdenv,
  fetchurl,
}:
let
  # Bump with `just pins-update ziggity`.
  pin = lib.importJSON ./ziggity.pin.json;
  asset =
    pin.assets.${stdenv.hostPlatform.system}
      or (throw "ziggity: unsupported system ${stdenv.hostPlatform.system}");
in
stdenv.mkDerivation {
  pname = "ziggity";
  inherit (pin) version;

  src = fetchurl { inherit (asset) url hash; };

  # The release archive is a single unpacked binary named `ziggity`, no wrapping directory.
  sourceRoot = ".";
  dontBuild = true;
  dontConfigure = true;

  installPhase = ''
    runHook preInstall
    install -Dm755 ziggity $out/bin/ziggity
    runHook postInstall
  '';

  meta = {
    description = "Ziggity CLI";
    homepage = "https://github.com/simoarpe/ziggity";
    license = lib.licenses.mit;
    platforms = builtins.attrNames pin.assets;
    mainProgram = "ziggity";
  };
}
