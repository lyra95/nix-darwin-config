inputs @ {
  home-manager,
  agenix,
  nixpkgs,
  ...
}: let
  pkgs = nixpkgs.legacyPackages."aarch64-darwin";
  name = "95hyouka";
  coreModules = {
    age = agenix.homeManagerModules.default;

    home = {
      home.username = name;
      home.homeDirectory = "/Users/${name}";
      home.stateVersion = "25.05";
    };
  };
  commonModules = {
    misc = {
      home.packages = with pkgs; [
        jq
        yq-go
        hex
        nix-search-cli
      ];

      programs.bash = {
        enable = true;
        historyControl = ["erasedups" "ignoredups" "ignorespace"];
        historyIgnore = ["ls" "cd" "exit"];
      };

      programs.starship = {
        enable = true;
        enableBashIntegration = true;

        # https://starship.rs/config/
        settings = {
          command_timeout = 1000;

          nix_shell = {
            heuristic = true;
          };
        };
      };

      # file explorer
      programs.yazi = {
        enable = true;
        enableBashIntegration = true;
      };

      # tmux alternative
      programs.zellij = {
        enable = true;
      };

      programs.direnv = {
        enable = true;
        enableBashIntegration = true;
        nix-direnv.enable = true;
      };

      # fuzzy finder (bash history, etc)
      programs.fzf = {
        enable = true;
        enableBashIntegration = true;
      };
    };

    modern = {
      home.packages = with pkgs; [
        bat-extras.batman # modern man
        delta # modern diff
      ];

      # modern ls
      programs.eza = {
        enable = true;
        enableBashIntegration = true;
        git = true;
        icons = "auto";
      };

      # modern grep
      programs.ripgrep.enable = true;

      # modern find
      programs.fd.enable = true;

      # modern cat
      programs.bat = {
        enable = true;
      };

      programs.bash = {
        shellAliases = {
          ls = "eza";
          ll = "eza -al";
          cat = "bat";
          tree = "eza --tree";
          find = "fd";
          grep = "rg";
          man = "batman";
          diff = "delta";
        };
      };
    };
  };
in {
  homeConfigurations."95hyouka" = home-manager.lib.homeManagerConfiguration {
    inherit pkgs;
    modules =
      [
        {
          imports = [
            ./modules/git
          ];
          git.enable = true;
        }
      ]
      ++ (builtins.attrValues commonModules)
      ++ (builtins.attrValues coreModules);
  };
}
