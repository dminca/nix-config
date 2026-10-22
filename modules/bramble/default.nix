{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.homelab.bramble;
in
{
  options.homelab.bramble = {
    enable = lib.mkEnableOption "Bramble Desktop (https://github.com/dminca/bramble)";

    package = lib.mkOption {
      type = lib.types.package;
      default = inputs.bramble.packages.${pkgs.stdenv.hostPlatform.system}.bramble;
      description = "Bramble Desktop package to install.";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ cfg.package ];
  };
}
