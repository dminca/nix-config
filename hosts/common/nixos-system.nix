{
  pkgs,
  ...
}:
{
  environment.systemPackages = with pkgs; [
    neovim
  ];
  nix.settings.experimental-features = "nix-command flakes";
  nix.enable = false;
  programs.zsh.enable = true;
  environment.etc."nix/nix.conf".text = ''
    allowed-users = *
    auto-optimise-store = false
    builders =
    cores = 0
    max-jobs = auto
    require-sigs = true
    sandbox = true
    sandbox-fallback = false
    substituters = https://cache.nixos.org/
    system-features = nixos-test benchmark big-parallel kvm
    trusted-public-keys = cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY=
    trusted-substituters =
    trusted-users = root
    extra-sandbox-paths =
  '';
}

