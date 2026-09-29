{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  cfg = config.homelab.ai.hermes;
  system = pkgs.stdenv.hostPlatform.system;

  hermesPackagesForSystem =
    if
      inputs ? "hermes-agent"
      && builtins.hasAttr "packages" inputs."hermes-agent"
      && builtins.hasAttr system inputs."hermes-agent".packages
    then
      inputs."hermes-agent".packages.${system}
    else
      null;

  defaultHermesPackage =
    if hermesPackagesForSystem != null then
      hermesPackagesForSystem.default
    else
      throw "homelab.ai.hermes: flake input `hermes-agent` is required and must provide packages for ${system}.";

  # Upstream only builds the Electron desktop shell for these flake systems
  # (see hermes-agent's flake.nix `systems` list minus aarch64-linux, which
  # this repo doesn't target).
  desktopSupportedSystems = [
    "x86_64-linux"
    "aarch64-darwin"
  ];

  defaultHermesDesktopPackage =
    if
      builtins.elem system desktopSupportedSystems
      && hermesPackagesForSystem != null
      && builtins.hasAttr "desktop" hermesPackagesForSystem
    then
      hermesPackagesForSystem.desktop
    else
      throw "homelab.ai.hermes.desktop: Hermes Desktop is only available on ${lib.concatStringsSep ", " desktopSupportedSystems} (current system: ${system}), or the hermes-agent flake input is missing its `desktop` package output.";

  freeModelsFile = pkgs.writeText "hermes-openrouter-free-models.txt" (
    lib.concatStringsSep "\n" cfg.openrouter.freeModels + "\n"
  );

  openrouterModelsBin = pkgs.writeShellScriptBin "hermes-openrouter-free-models" ''
    cat ${freeModelsFile}
  '';

in
{
  options.homelab.ai.hermes = {
    enable = lib.mkEnableOption "Hermes Agent with OpenRouter defaults";

    package = lib.mkOption {
      type = lib.types.package;
      default = defaultHermesPackage;
      description = "Hermes Agent package to install.";
    };

    openrouter = {
      enable = lib.mkEnableOption "OpenRouter defaults for Hermes Agent";

      baseUrl = lib.mkOption {
        type = lib.types.str;
        default = "https://openrouter.ai/api/v1";
        description = "OpenRouter base URL used by Hermes.";
      };

      defaultModel = lib.mkOption {
        type = lib.types.str;
        default = "openai/gpt-oss-20b:free";
        description = "Default OpenRouter model for Hermes sessions.";
      };

      freeModels = lib.mkOption {
        type = with lib.types; listOf str;
        default = [
          "openai/gpt-oss-20b:free"
          "openai/gpt-oss-120b:free"
          "meta-llama/llama-3.3-8b-instruct:free"
          "google/gemma-3n-e4b-it:free"
          "mistralai/mistral-small-3.2-24b-instruct:free"
          "qwen/qwen3-coder:free"
        ];
        description = ''
          OpenRouter models to treat as the free-model allowlist in this configuration.
          This list is intentionally configurable because OpenRouter free offerings can change.
        '';
      };

      apiKeyFile = lib.mkOption {
        type = with lib.types; nullOr path;
        default = null;
        description = ''
          Path to a file containing OPENROUTER_API_KEY=... .
          When set, it is exposed at /etc/hermes/openrouter-api-key.
        '';
      };
    };

    desktop = {
      enable = lib.mkEnableOption "Hermes Desktop (Electron GUI); supported on x86_64-linux and aarch64-darwin";

      package = lib.mkOption {
        type = lib.types.package;
        default = defaultHermesDesktopPackage;
        description = "Hermes Desktop package to install.";
      };
    };

  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages =
      [ cfg.package openrouterModelsBin ]
      ++ lib.optional cfg.desktop.enable cfg.desktop.package;

    environment.etc."hermes/openrouter-free-models".source = freeModelsFile;

    # `.source =` forces the given path to exist at eval time (it's a
    # Nix-store import), which breaks for any secret manager (sops-nix,
    # agenix, ...) whose file only materializes during activation. A
    # symlink instead only needs the target to resolve when something
    # later *reads* through it, not when this module evaluates.
    system.activationScripts.hermesOpenrouterApiKey.text =
      lib.optionalString (cfg.openrouter.enable && cfg.openrouter.apiKeyFile != null) ''
        mkdir -p /etc/hermes
        ln -sf ${lib.escapeShellArg cfg.openrouter.apiKeyFile} /etc/hermes/openrouter-api-key
      '';

    environment.variables =
      lib.optionalAttrs cfg.openrouter.enable {
        OPENROUTER_BASE_URL = cfg.openrouter.baseUrl;
        HERMES_OPENROUTER_DEFAULT_MODEL = cfg.openrouter.defaultModel;
      }
      // {
        HERMES_OPENROUTER_FREE_MODELS_PATH = "/etc/hermes/openrouter-free-models";
      };

  };
}
