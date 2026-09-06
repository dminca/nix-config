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

  configYaml =
    (lib.optionalString cfg.local.enable ''
      model:
        default: "${cfg.local.model}"
        provider: "llamacpp"

      local_runtime:
        enabled: true
        backend: ${cfg.local.backend}
    ''
    + lib.optionalString (cfg.local.tag != null) ''
        tag: ${cfg.local.tag}
    ''
    )
    + lib.optionalString cfg.openrouter.enable ''
      fallback_providers:
        - provider: openrouter
          model: "${cfg.openrouter.defaultModel}"
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

    local = {
      enable = lib.mkEnableOption "Hermes managed llama.cpp local runtime";

      backend = lib.mkOption {
        type = lib.types.enum [
          "auto"
          "cpu"
          "cuda"
          "metal"
          "vulkan"
          "hip"
        ];
        default = "cpu";
        description = "Hermes local-runtime backend selection.";
      };

      model = lib.mkOption {
        type = lib.types.str;
        default = "gemma2:9b";
        description = "Local model name to set as Hermes default.";
      };

      apiTimeout = lib.mkOption {
        type = lib.types.int;
        default = 1800;
        description = "Stream/API timeout used for slower local inference.";
      };

      tag = lib.mkOption {
        type = with lib.types; nullOr str;
        default = null;
        description = "Optional pinned llama.cpp runtime tag for Hermes local runtime.";
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
      // lib.optionalAttrs cfg.local.enable {
        HERMES_API_TIMEOUT = toString cfg.local.apiTimeout;
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

    home.file = lib.optionalAttrs cfg.local.enable {
      ".hermes/config.yaml".text = configYaml;
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
