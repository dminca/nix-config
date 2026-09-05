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

  ponytailInstallBin = pkgs.writeShellScriptBin "hermes-ponytail-install" ''
    set -eu
    exec ${cfg.package}/bin/hermes plugins install ${lib.escapeShellArg cfg.ponytail.pluginRef} --enable
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
        description = "Whether to run a systemd oneshot that installs the Ponytail plugin for a target user.";
      };

      user = lib.mkOption {
        type = with lib.types; nullOr str;
        default = null;
        description = "User account that receives the Ponytail plugin when autoInstall is enabled.";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages =
      [ cfg.package openrouterModelsBin ]
      ++ lib.optional cfg.ponytail.enable ponytailInstallBin;

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

    assertions = [
      {
        assertion = !(cfg.ponytail.enable && cfg.ponytail.autoInstall && cfg.ponytail.user == null);
        message = "homelab.ai.hermes.ponytail.user must be set when homelab.ai.hermes.ponytail.autoInstall is true.";
      }
    ];

    systemd.services.hermes-ponytail-install = lib.mkIf (cfg.ponytail.enable && cfg.ponytail.autoInstall) {
      description = "Install Ponytail plugin for Hermes Agent";
      wantedBy = [ "multi-user.target" ];
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      serviceConfig = {
        Type = "oneshot";
        User = cfg.ponytail.user;
        ExecStart = lib.escapeShellArgs [
          "${cfg.package}/bin/hermes"
          "plugins"
          "install"
          cfg.ponytail.pluginRef
          "--enable"
        ];
      };
    };

  };
}
