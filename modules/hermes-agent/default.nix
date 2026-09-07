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
  defaultHermesPackage =
    if
      inputs ? "hermes-agent"
      && builtins.hasAttr "packages" inputs."hermes-agent"
      && builtins.hasAttr system inputs."hermes-agent".packages
    then
      inputs."hermes-agent".packages.${system}.default
    else
      throw "homelab.ai.hermes: flake input `hermes-agent` is required and must provide packages for ${system}.";

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

  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages =
      [ cfg.package openrouterModelsBin ];

    environment.etc =
      {
        "hermes/openrouter-free-models".source = freeModelsFile;
      }
      // lib.optionalAttrs (cfg.openrouter.enable && cfg.openrouter.apiKeyFile != null) {
        "hermes/openrouter-api-key".source = cfg.openrouter.apiKeyFile;
      };

    environment.sessionVariables =
      lib.optionalAttrs cfg.openrouter.enable {
        OPENROUTER_BASE_URL = cfg.openrouter.baseUrl;
        HERMES_OPENROUTER_DEFAULT_MODEL = cfg.openrouter.defaultModel;
      }
      // {
        HERMES_OPENROUTER_FREE_MODELS_PATH = "/etc/hermes/openrouter-free-models";
      };

  };
}
