{ config, ... }:
{
  programs.zed-editor = {
    enable = true;
    extensions = [
      "nix"
      "just"
    ];
    userSettings.agent_servers."hermes-agent" = {
      type = "custom";
      command = "${config.profiles.ai.hermes.package}/bin/hermes";
      args = [ "acp" ];
    };
  };
}
