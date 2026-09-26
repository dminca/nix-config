{
  lib,
  stdenv,
  fetchurl,
}:
let
  version = "0.47.0";

  # Maps Nix's `system` string to ziggity's release asset suffix + sha256.
  # To upgrade: bump `version` and update the two hashes below from
  # https://github.com/simoarpe/ziggity/releases/download/v<version>/checksums.txt
  platforms = {
    x86_64-linux = {
      suffix = "x86_64-linux-musl";
      sha256 = "46b1f08c34d9b7b8819940470c3a020bdfc3a29ef882e701352e634b5bf88486";
    };
    aarch64-darwin = {
      suffix = "aarch64-macos";
      sha256 = "541327fed38155c63c4cc2d00ff07e53f72bf5e2afb591f813b379b2851a3f3d";
    };
  };

  platform =
    platforms.${stdenv.hostPlatform.system}
      or (throw "ziggity: unsupported system ${stdenv.hostPlatform.system}");
in
stdenv.mkDerivation {
  pname = "ziggity";
  inherit version;

  src = fetchurl {
    url = "https://github.com/simoarpe/ziggity/releases/download/v${version}/ziggity-v${version}-${platform.suffix}.tar.gz";
    inherit (platform) sha256;
  };

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
    platforms = builtins.attrNames platforms;
    mainProgram = "ziggity";
  };
}
