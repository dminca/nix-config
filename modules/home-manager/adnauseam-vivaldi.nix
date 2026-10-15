{ lib, pkgs, ... }:

let
  extensionZip = pkgs.fetchurl {
    url = "https://github.com/dhowe/AdNauseam/releases/download/v3.29.2/adnauseam-3.29.2.chromium.zip";
    hash = "sha256-LHJB29HscbFvL4iDgwWVt04mA4lvPyg61QCwcO28msE=";
  };
  extensionDir = pkgs.stdenvNoCC.mkDerivation {
    pname = "adnauseam-chromium";
    version = "3.29.2";

    src = extensionZip;
    nativeBuildInputs = [ pkgs.unzip ];
    dontUnpack = true;

    installPhase = ''
      mkdir -p "$out"
      unzip -q "$src" -d "$out"
    '';
  };

  vivaldiAdnauseam = pkgs.writeShellApplication {
    name = "vivaldi-adnauseam";
    text = ''
      set -euo pipefail

      ext_dir="${extensionDir}/adnauseam.chromium"

      case "$(uname -s)" in
        Darwin)
          exec open -a Vivaldi --args \
            --disable-features=ExtensionManifestV2Unsupported \
            --load-extension="$ext_dir" \
            "$@"
          ;;
        Linux)
          exec vivaldi \
            --disable-features=ExtensionManifestV2Unsupported \
            --load-extension="$ext_dir" \
            "$@"
          ;;
        *)
          echo "unsupported platform for vivaldi-adnauseam" >&2
          exit 1
          ;;
      esac
    '';
  };
in
{
  home.packages = [ vivaldiAdnauseam ];

  xdg.desktopEntries = lib.mkIf pkgs.stdenv.isLinux {
    vivaldi-adnauseam = {
      name = "Vivaldi (AdNauseam)";
      genericName = "Web Browser";
      exec = "${lib.getExe vivaldiAdnauseam}";
      icon = "vivaldi";
      categories = [
        "Network"
        "WebBrowser"
      ];
      terminal = false;
    };
  };
}
