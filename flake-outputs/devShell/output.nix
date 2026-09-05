inputs @ {
  self,
  nixpkgs,
  devshell,
  ...
}: system: let
  lib = nixpkgs.lib;
  pkgs = nixpkgs.legacyPackages.${system};
  mkShell =
    (import devshell {
      inherit system;
      nixpkgs = pkgs;
    }).mkShell;
in {
  # `nix flake check` does not evaluate `darwinConfigurations` or
  # `homeConfigurations` on its own; it only checks that the outputs exist. Re-
  # exposing them as checks is what makes `nix flake check` actually evaluate and
  # build them, so eval errors and failed assertions are caught here.
  checks =
    lib.optionalAttrs (system == "aarch64-darwin")
    (
      lib.mapAttrs'
      (name: cfg: lib.nameValuePair "darwin-${name}" cfg.config.system.build.toplevel)
      self.darwinConfigurations
      // lib.mapAttrs'
      (name: cfg: lib.nameValuePair "home-${name}" cfg.activationPackage)
      self.homeConfigurations
    );
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
        command = "sudo darwin-rebuild switch --flake $PRJ_ROOT#95hyoukas-MacBook-Air";
      }
      {
        help = "home-manager switch";
        name = "hs";
        command = "home-manager switch --flake $PRJ_ROOT#95hyouka";
      }
      {
        help = "update flake inputs";
        name = "update";
        command = "nix flake update --commit-lock-file";
      }
    ];
  };
}
