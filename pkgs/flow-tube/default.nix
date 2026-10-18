{
  lib,
  stdenvNoCC,
  fetchurl,
  undmg,
  makeBinaryWrapper,
  rcodesign,
  nodejs,
  appimageTools,
}:
let
  pname = "flow-tube";
  # Bump with `just pins-update flow-tube`.
  pin = lib.importJSON ./flow-tube.pin.json;
  inherit (pin) version;
  meta = {
    description = "Privacy-first YouTube and YouTube Music desktop client";
    homepage = "https://github.com/Flow-Tube/Flow-Desktop";
    license = lib.licenses.gpl3Only;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    platforms = builtins.attrNames pin.assets;
    mainProgram = pname;
  };
  linuxSrc = fetchurl { inherit (pin.assets.x86_64-linux) url hash; };
  appimageContents = appimageTools.extractType2 {
    inherit pname version;
    src = linuxSrc;
  };
in
if stdenvNoCC.hostPlatform.isDarwin then
  stdenvNoCC.mkDerivation {
    inherit pname version meta;
    src = fetchurl { inherit (pin.assets.aarch64-darwin) url hash; };
    nativeBuildInputs = [
      undmg
      makeBinaryWrapper
      rcodesign
    ];
    sourceRoot = ".";
    dontConfigure = true;
    dontBuild = true;
    dontFixup = true;
    installPhase = ''
      runHook preInstall
      mkdir -p "$out/Applications" "$out/bin"
      cp -R "Flow Beta.app" "$out/Applications/"
      wrapProgram "$out/Applications/Flow Beta.app/Contents/MacOS/flow" \
        --set FLOW_NODE "${lib.getExe nodejs}" \
        --set FLOW_INTEGRITY_SCRIPT "$out/Applications/Flow Beta.app/Contents/Resources/sidecar/integrity.cjs"
      ln -s "$out/Applications/Flow Beta.app/Contents/MacOS/flow" "$out/bin/${pname}"
      # Re-seal the app after replacing its launcher with a native wrapper.
      rcodesign sign "$out/Applications/Flow Beta.app"
      runHook postInstall
    '';
    doInstallCheck = true;
    installCheckPhase = ''
      runHook preInstallCheck
      test -x "$out/bin/${pname}"
      ${lib.getExe nodejs} --check "$out/Applications/Flow Beta.app/Contents/Resources/sidecar/integrity.cjs"
      runHook postInstallCheck
    '';
  }
else
  appimageTools.wrapType2 {
    inherit pname version meta;
    src = linuxSrc;
    extraPkgs = pkgs: [
      pkgs.nodejs
      pkgs.webkitgtk_4_1
      pkgs.gst_all_1.gst-plugins-good
      pkgs.gst_all_1.gst-plugins-bad
      pkgs.gst_all_1.gst-libav
    ];
    profile = ''
      export FLOW_NODE="${lib.getExe nodejs}"
      export FLOW_INTEGRITY_SCRIPT="${appimageContents}/usr/lib/Flow Beta/sidecar/integrity.cjs"
    '';
    extraInstallCommands = ''
      install -Dm644 "${appimageContents}/Flow Beta.desktop" "$out/share/applications/flow-tube.desktop"
      substituteInPlace "$out/share/applications/flow-tube.desktop" \
        --replace-fail "Exec=flow" "Exec=$out/bin/${pname}"
      install -Dm644 "${appimageContents}/usr/share/icons/hicolor/128x128/apps/flow.png" "$out/share/icons/hicolor/128x128/apps/flow.png"
    '';
  }
