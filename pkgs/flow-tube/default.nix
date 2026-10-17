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
  version = "0.1.0-beta2";
  baseUrl = "https://github.com/Flow-Tube/Flow-Desktop/releases/download/v${version}";
  meta = {
    description = "Privacy-first YouTube and YouTube Music desktop client";
    homepage = "https://github.com/Flow-Tube/Flow-Desktop";
    license = lib.licenses.gpl3Only;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    platforms = [
      "aarch64-darwin"
      "x86_64-linux"
    ];
    mainProgram = pname;
  };
  linuxSrc = fetchurl {
    url = "${baseUrl}/Flow_${version}_linux_amd64.AppImage";
    sha256 = "a48a1e46db1f167e7b5c590c6406661a592cb276fc1518b71dfe243a07dafa91";
  };
  appimageContents = appimageTools.extractType2 {
    inherit pname version;
    src = linuxSrc;
  };
in
if stdenvNoCC.hostPlatform.isDarwin then
  stdenvNoCC.mkDerivation {
    inherit pname version meta;
    src = fetchurl {
      url = "${baseUrl}/Flow_${version}_darwin_aarch64.dmg";
      sha256 = "922c35eb3ca136d071534dddf27fedb58db9f2aab9d0d8265eafd2b3911c0742";
    };
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
