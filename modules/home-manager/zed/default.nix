{ config, ... }:
{
  programs.zed-editor = {
    enable = true;
    userSettings.agent_servers."hermes-agent" = {
      type = "custom";
      command = "${config.profiles.ai.hermes.package}/bin/hermes";
      args = [ "acp" ];
    };
  };
}
