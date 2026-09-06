{
  pkgs,
  lib,
  stdenv,
  makeWrapper,
  hermesNpmLib,
  electron,
  hermesAgent,
  python3,
  sourceRoot,
  # Environment to bake into the launcher. A GUI launcher reads none of the
  # shell profile, so a variable that an interactive shell exports does not
  # reach an app that the desktop menu starts.
  extraEnv ? { },
  # Shell lines to run before the app starts.
  extraRun ? [ ],
  ...
}:
let
  extraEnvFlags = lib.concatMapStrings (
    name: " \\\n      --set ${name} ${lib.escapeShellArg (toString extraEnv.${name})}"
  ) (lib.attrNames extraEnv);

  extraRunFlags = lib.concatMapStrings (line: " \\\n      --run ${lib.escapeShellArg line}") extraRun;

  electronHeaders = pkgs.fetchurl {
    url = "https://artifacts.electronjs.org/headers/dist/v${electron.version}/node-v${electron.version}-headers.tar.gz";
    sha256 = "sha256-hTtfw9v84VeIn2vP/S3EE+N021PT6cJWGI6I3nWd3to=";
  };

  targetPlatform =
    if stdenv.hostPlatform.isDarwin then
      "darwin"
    else if stdenv.hostPlatform.isLinux then
      "linux"
    else
      throw "hermes-desktop: unsupported host platform for node-pty staging";

  targetArch =
    if stdenv.hostPlatform.isAarch64 then
      "arm64"
    else if stdenv.hostPlatform.isx86_64 then
      "x64"
    else
      throw "hermes-desktop: unsupported host arch for node-pty staging";

  renderer = hermesNpmLib.buildNpmPackage {
    dirs = [
      "apps/desktop"
      "apps/shared"
    ];
    pname = "hermes-desktop-renderer";

    doCheck = true;

    buildPhase = ''
      runHook preBuild

      mkdir -p apps/desktop/build

      patchShebangs .

      pushd apps/desktop
        npm exec -- tsc -b
        npm exec -- vite build
        node scripts/bundle-electron-main.mjs

        mkdir -p "$TMPDIR/electron-headers"
        tar -xzf ${electronHeaders} -C "$TMPDIR/electron-headers" --strip-components=1

        ${lib.getExe hermesNpmLib.node-gyp} rebuild \
          --directory=../../node_modules/node-pty \
          --build-from-source \
          --runtime=electron \
          --target=${electron.version} \
          --nodedir="$TMPDIR/electron-headers" \
          --disturl="" \
          --offline

        node scripts/stage-native-deps.mjs ${targetPlatform} ${targetArch}
      popd

      runHook postBuild
    '';

    checkPhase = ''
      runHook preCheck

      pushd apps/desktop
        npm run postbuild

        STAGED_PTY_NODE="./dist/node_modules/node-pty/build/Release/pty.node"
        if [ ! -f "$STAGED_PTY_NODE" ]; then
          echo "FATAL: Missing staged node-pty native binary at $STAGED_PTY_NODE"
          exit 1
        fi
      popd

      runHook postCheck
    '';

    installPhase = ''
      runHook preInstall
      mkdir -p $out
      cp -rn apps/desktop/dist $out/
      echo '{"schemaVersion":1,"commit":"nix-dummy-commit","branch":"nix","dirty":false,"source":"nix"}' > $out/install-stamp.json
      cp -n apps/desktop/package.json $out/
      runHook postInstall
    '';
  };
in
stdenv.mkDerivation {
  pname = "hermes-desktop";
  inherit (renderer) version;

  dontUnpack = true;
  dontBuild = true;

  nativeBuildInputs = [
    makeWrapper
    python3
  ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/share/hermes-desktop $out/bin
    cp -r ${renderer}/* $out/share/hermes-desktop/

    substituteInPlace $out/share/hermes-desktop/dist/electron-main.mjs \
      --replace-fail "process.resourcesPath" "'$out/share/hermes-desktop'"

    makeWrapper ${lib.getExe electron} $out/bin/hermes-desktop \
      --add-flags "$out/share/hermes-desktop" \
      --set HERMES_DESKTOP_HERMES "${lib.getExe hermesAgent}" \
      --set ELECTRON_IS_DEV 0${extraEnvFlags}${extraRunFlags}

    mkdir -p $out/share/applications $out/share/icons/hicolor/1024x1024/apps
    install -m 0644 ${sourceRoot}/apps/desktop/assets/icon.png \
      $out/share/icons/hicolor/1024x1024/apps/hermes.png
    export PYTHONPATH=$(mktemp -d)
    cp ${sourceRoot}/hermes_cli/linux_desktop_entry.py "$PYTHONPATH/linux_desktop_entry.py"
    export DESKTOP_EXEC="$out/bin/hermes-desktop"
    export DESKTOP_ICON="$out/share/icons/hicolor/1024x1024/apps/hermes.png"
    python3 -c 'import os; from linux_desktop_entry import render_desktop_entry; print(render_desktop_entry(os.environ["DESKTOP_EXEC"], os.environ["DESKTOP_ICON"]))' > $out/share/applications/hermes.desktop
    runHook postInstall
  '';

  passthru = {
    inherit (renderer.passthru) packageJsonPath;
  };

  meta = with lib; {
    description = "Native Electron desktop shell for Hermes Agent";
    homepage = "https://github.com/NousResearch/hermes-agent";
    license = licenses.mit;
    platforms = platforms.unix;
    mainProgram = "hermes-desktop";
  };
}
