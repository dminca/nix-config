{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  cfg = config.profiles.ai.hermes;
  system = pkgs.stdenv.hostPlatform.system;
  defaultHermesPackage =
    if
      inputs ? "hermes-agent"
      && builtins.hasAttr "packages" inputs."hermes-agent"
      && builtins.hasAttr system inputs."hermes-agent".packages
    then
      inputs."hermes-agent".packages.${system}.default
    else
      throw "profiles.ai.hermes: flake input `hermes-agent` is required and must provide packages for ${system}.";

  freeModelsFile = pkgs.writeText "hermes-openrouter-free-models.txt" (
    lib.concatStringsSep "\n" cfg.openrouter.freeModels + "\n"
  );

  openrouterModelsBin = pkgs.writeShellScriptBin "hermes-openrouter-free-models" ''
    cat ${freeModelsFile}
  '';

  ponytailInstallBin = pkgs.writeShellScriptBin "hermes-ponytail-install" ''
    set -eu
    exec ${cfg.package}/bin/hermes plugins install ${lib.escapeShellArg cfg.ponytail.pluginRef} --enable
  '';
in
{
  options.profiles.ai.hermes = {
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
          When set, it is exposed under ~/.config/hermes/openrouter-api-key.
        '';
      };
    };

    ponytail = {
      enable = lib.mkEnableOption "Ponytail plugin bootstrap helper for Hermes";

      pluginRef = lib.mkOption {
        type = lib.types.str;
        default = "DietrichGebert/ponytail";
        description = "Plugin reference used by `hermes plugins install`.";
      };

      autoInstall = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Whether to install/enable Ponytail during Home Manager activation.";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages =
      [ cfg.package openrouterModelsBin ]
      ++ lib.optional cfg.ponytail.enable ponytailInstallBin;

    home.sessionVariables =
      lib.optionalAttrs cfg.openrouter.enable {
        OPENROUTER_BASE_URL = cfg.openrouter.baseUrl;
        HERMES_OPENROUTER_DEFAULT_MODEL = cfg.openrouter.defaultModel;
      }
      // {
        HERMES_OPENROUTER_FREE_MODELS_PATH = "${config.xdg.configHome}/hermes/openrouter-free-models";
      };

    xdg.configFile =
      {
        "hermes/openrouter-free-models".source = freeModelsFile;
      }
      // lib.optionalAttrs (cfg.openrouter.enable && cfg.openrouter.apiKeyFile != null) {
        "hermes/openrouter-api-key".source = cfg.openrouter.apiKeyFile;
      };

    home.activation.hermesPonytailInstall = lib.mkIf (cfg.ponytail.enable && cfg.ponytail.autoInstall) (lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        if [ ! -f "${config.home.homeDirectory}/.hermes/.nix-ponytail-installed" ]; then
          $DRY_RUN_CMD ${lib.escapeShellArgs [
            "${cfg.package}/bin/hermes"
            "plugins"
            "install"
            cfg.ponytail.pluginRef
            "--enable"
          ]}
          $DRY_RUN_CMD mkdir -p "${config.home.homeDirectory}/.hermes"
          $DRY_RUN_CMD touch "${config.home.homeDirectory}/.hermes/.nix-ponytail-installed"
        fi
      '');
  };
}
