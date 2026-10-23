{
  lib,
  pkgs,
  ...
}:
let
  buildFirefoxXpiAddon =
    {
      pname,
      version,
      addonId,
      url,
      hash,
      meta ? { },
    }:
    pkgs.stdenvNoCC.mkDerivation {
      inherit pname version meta;
      src = pkgs.fetchurl {
        inherit url hash;
      };
      dontUnpack = true;
      installPhase = ''
        runHook preInstall
        install -Dm644 "$src" "$out/share/mozilla/extensions/{ec8030f7-c20a-464f-9b0e-13a3a9e97384}/${addonId}.xpi"
        runHook postInstall
      '';
    };
in
{
  programs.firefox = {
    enable = true;
    profiles.default = {
      isDefault = true;
      settings = {
        "extensions.autoDisableScopes" = 0;
        "browser.startup.page" = 3;
      };
      extensions.packages = [
        (buildFirefoxXpiAddon {
          pname = "hister";
          inherit (lib.importJSON ./hister.pin.json)
            version
            addonId
            url
            hash
            ;
          meta = {
            description = "Web history on steroids";
            homepage = "https://addons.mozilla.org/en-US/firefox/addon/hister/";
            platforms = lib.platforms.all;
          };
        })
        (buildFirefoxXpiAddon {
          pname = "bramble";
          inherit (lib.importJSON ./bramble.pin.json)
            version
            addonId
            url
            hash
            ;
          meta = {
            description = "Local-first, encrypted password manager";
            homepage = "https://addons.mozilla.org/en-US/firefox/addon/bramble/";
            platforms = lib.platforms.all;
          };
        })
      ];
    };
  };
}
