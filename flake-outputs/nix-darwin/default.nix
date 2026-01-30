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

        security.pam.services.sudo_local.touchIdAuth = true;

        system.defaults.finder = {
          AppleShowAllExtensions = true;
          AppleShowAllFiles = true;
        };
      }
      (import ./modules/aerospace)
      {
        environment.systemPackages = [
          pkgs.duti
        ];

        # https://github.com/nix-darwin/nix-darwin/issues/663
        # https://github.com/nix-darwin/nix-darwin/blob/0fc4e7ac670a0ed874abacf73c4b072a6a58064b/modules/system/activation-scripts.nix#L118
        system.activationScripts = {
          # https://github.com/nix-darwin/nix-darwin/issues/1506
          # Setting default apps using nix-darwin is currently not implemented.
          # So this:
          postActivation.text = ''
            set -euo pipefail

            function set_default_app() {
              local target_bundle_id="$1"
              local uti="$2"
              local target_user="$3"

              current_default_app=$(sudo -u "$target_user" ${pkgs.duti}/bin/duti -d "$uti" || true)
              if [ "$current_default_app" != "$target_bundle_id" ]; then
                sudo -u "$target_user" ${pkgs.duti}/bin/duti -s "$target_bundle_id" "$uti" all
              fi
            }

            tuples=(
              "stirling.pdf.dev:com.adobe.pdf"
              "com.microsoft.VSCode:public.plain-text"
              "com.microsoft.VSCode:public.source-code"
              "com.microsoft.VSCode:public.data"
            )

            for t in "''${tuples[@]}"; do
              bundle_id="''${t%%:*}"
              uti="''${t#*:}"
              set_default_app "$bundle_id" "$uti" "${profile.userName}"
            done
          '';
        };
      }
    ];
  };
}
