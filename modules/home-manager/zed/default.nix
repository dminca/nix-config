{ config, lib, ... }:
{
  programs.zed-editor = {
    enable = true;
    extensions = [
      "nix"
      "just"
    ];
    userSettings.agent_servers."hermes-agent" = lib.mkIf config.profiles.ai.hermes.enable {
      type = "custom";
      command = "${config.profiles.ai.hermes.package}/bin/hermes";
      args = [ "acp" ];
    };
  };
}
