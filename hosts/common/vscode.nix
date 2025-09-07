{
  pkgs,
  lib,
  ...
}:
{
  programs.vscode = {
    enable = true;
    package = pkgs.vscodium;
    profiles.default = {
      enableUpdateCheck = false;
      enableExtensionUpdateCheck = false;
      extensions = with pkgs.vscode-extensions; [
        jnoortheen.nix-ide
        redhat.vscode-yaml
        golang.go
        oderwat.indent-rainbow
        hashicorp.terraform
      ] ++ pkgs.vscode-utils.extensionsFromVscodeMarketplace [
        {
          name = "vscode-jsonnet";
          publisher = "grafana";
          version = "0.7.2";
          sha256 = "sha256-Q8VzXzTdHo9h5+eCHHF1bPomPEbRsvouJcUfmFUDGMU=";
        }
      ];
      keybindings = [
        {
          key = "ctrl+shift+q";
          command = "workbench.action.toggleMaximizedPanel";
        }
        {
          key = "ctrl+shift+left";
          command = "workbench.action.splitEditorLeft";
        }
        {
          key = "ctrl+shift+right";
          command = "workbench.action.splitEditorRight";
        }
        {
          key = "ctrl+shift+down";
          command = "workbench.action.splitEditorDown";
        }
        {
          key = "ctrl+shift+up";
          command = "workbench.action.splitEditorUp";
        }
        {
          key = "ctrl+cmd+up";
          command = "workbench.action.moveEditorToAboveGroup";
        }
        {
          key = "ctrl+cmd+down";
          command = "workbench.action.moveEditorToBelowGroup";
        }
        {
          key = "cmd+\\";
          command = "-workbench.action.splitEditor";
        }
      ];
      userSettings = {
        "indentRainbow.colors" = [
          "rgba(255,255,64,0.07)"
          "rgba(127,255,127,0.07)"
          "rgba(255,127,255,0.07)"
          "rgba(79,236,236,0.07)"
        ];
        "workbench.sideBar.location" = "right";
        "editor.renderWhitespace" = "all";
        "editor.rulers" = [ 79 ];
        "redhat.telemetry.enabled" = false;
        "breadcrumbs.enabled" = true;
        "explorer.autoReveal" = false;
        "explorer.compactFolders" = true;
        "go.toolsManagement.autoUpdate" = true;
        "editor.fontFamily" = "JetBrainsMono Nerd Font";
        "editor.fontLigatures" = false;
        "editor.fontSize" = 12;
        "gitlens.launchpad.indicator.enabled" = false;
        "nix.formatterPath" = "${lib.getExe pkgs.nixfmt-classic}";
        "nix.serverPath" = "${lib.getExe pkgs.nil}";
        "nix.enableLanguageServer" = true;
        "window.autoDetectColorScheme" = true;
        "workbench.preferredDarkColorTheme" = "Default Dark Modern";
        "workbench.preferredHighContrastColorTheme" = "Default Light Modern";
        "files.autoSave" = "onFocusChange";
      };
    };
  };
}
