inputs @ {
  nixpkgs,
  devshell,
  ...
}: system: let
  pkgs = nixpkgs.legacyPackages.${system};
  mkShell =
    (import devshell {
      inherit system;
      nixpkgs = pkgs;
    }).mkShell;
in {
  checks = {};
  formatter = pkgs.alejandra;
  devShells.default = mkShell {
    packages = [
      pkgs.alejandra
    ];

    commands = [
      {
        help = "run formatter";
        name = "fmt";
        command = ''
          alejandra "$PRJ_ROOT"
        '';
      }
      {
        help = "debug nix expression";
        name = "debug";
        command = ''
          nix repl --extra-experimental-features 'flakes repl-flake' "$PRJ_ROOT"
        '';
      }
      {
        help = "darwin switch";
        name = "ds";
        command = "darwin-rebuild switch --flake $PRJ_ROOT#95hyoukas-MacBook-Air";
      }
      {
        help = "home-manager switch";
        name = "hs";
        command = "home-manager switch --flake $PRJ_ROOT#95hyouka";
      }
    ];
  };
}
