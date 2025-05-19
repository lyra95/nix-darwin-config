# system-wide configurations
inputs @ {
  nix-darwin,
  nixpkgs,
  ...
}: let
  profile = {
    userName = "95hyouka";
    hostName = "95hyoukas-MacBook-Air";
  };
  pkgs = nixpkgs.legacyPackages."aarch64-darwin";
in {
  darwinConfigurations."${profile.hostName}" = nix-darwin.lib.darwinSystem {
    modules = [
      (import ./modules/dunno.nix inputs)
      (import ./modules/homebrew profile inputs)
      {
        fonts.packages = [pkgs.d2coding];

        environment.systemPackages = [
          pkgs.vim
          pkgs.git
          pkgs.direnv
        ];

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
