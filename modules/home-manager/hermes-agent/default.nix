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

  effectiveProvider =
    if cfg.local.enable then
      "llamacpp"
    else if cfg.openrouter.enable then
      "openrouter"
    else
      null;

  effectiveDefaultModel =
    if cfg.local.enable then
      cfg.local.model
    else if cfg.openrouter.enable then
      cfg.openrouter.defaultModel
    else
      null;

  configYaml =
    lib.optionalString (effectiveProvider != null && effectiveDefaultModel != null) ''
      model:
        provider: "${effectiveProvider}"
        default: "${effectiveDefaultModel}"
    ''
    + lib.optionalString cfg.local.enable (
      ''
        local_runtime:
          enabled: true
          backend: ${cfg.local.backend}
      ''
      + lib.optionalString (cfg.local.tag != null) ''
        tag: ${cfg.local.tag}
      ''
    )
    + lib.optionalString (cfg.local.enable && cfg.openrouter.enable) ''
      fallback_providers:
        - provider: openrouter
          model: "${cfg.openrouter.defaultModel}"
    ''
    + lib.optionalString (cfg.scanOnInstall != null) ''
      plugins:
        scan_on_install: ${if cfg.scanOnInstall then "true" else "false"}
    '';

  configYamlFile = pkgs.writeText "hermes-config.yaml" configYaml;
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
        default = "thinkingmachines/inkling:free";
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

    scanOnInstall = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable Hermes plugin scanner on install.";
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
    home.packages = [
      cfg.package
      openrouterModelsBin
    ];

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

    xdg.configFile = {
      "hermes/openrouter-free-models".source = freeModelsFile;
    }
    // lib.optionalAttrs (cfg.openrouter.enable && cfg.openrouter.apiKeyFile != null) {
      "hermes/openrouter-api-key".source = cfg.openrouter.apiKeyFile;
    };

    home.activation.hermesConfigSeed = lib.mkIf cfg.enable (lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      hermes_dir="${config.home.homeDirectory}/.hermes"
      hermes_config="$hermes_dir/config.yaml"

      if [ -L "$hermes_config" ]; then
        $DRY_RUN_CMD rm "$hermes_config"
      fi

      if [ ! -e "$hermes_config" ]; then
        $DRY_RUN_CMD mkdir -p "$hermes_dir"
        $DRY_RUN_CMD install -m 0600 ${configYamlFile} "$hermes_config"
      fi
    '');

  };
}
