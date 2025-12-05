# system-wide configurations
inputs @ {
  nix-darwin,
  nixpkgs,
  ...
}: let
  profile = {
    userName = "95hyouka";
    hostName = "95hyoukas-MacBook-Air";
    arch = "aarch64-darwin";
  };
  pkgs = nixpkgs.legacyPackages."${profile.arch}";
in {
  darwinConfigurations."${profile.hostName}" = nix-darwin.lib.darwinSystem {
    modules = [
      (import ./modules/dunno.nix profile inputs)
      (import ./modules/homebrew profile inputs)
      {
        fonts.packages = [pkgs.d2coding];

        environment.systemPackages = [
          pkgs.vim
          pkgs.git
          pkgs.direnv
          pkgs.home-manager
        ];

        system.primaryUser = profile.userName;

        system.defaults.NSGlobalDomain.AppleShowAllExtensions = true;
        system.defaults.NSGlobalDomain.AppleShowAllFiles = true;

        system.defaults.screencapture.target = "clipboard";

        nix.settings.experimental-features = "nix-command flakes";

        system.defaults.finder = {
          AppleShowAllExtensions = true;
          AppleShowAllFiles = true;
        };
      }
      (import ./modules/aerospace)
    ];
  };
}
