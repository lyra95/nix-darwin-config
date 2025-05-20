{
  config,
  lib,
  ...
}: {
  options = {
    git.enable = lib.mkEnableOption "enable git";
  };

  config = lib.mkIf config.git.enable {
    assertions = [
      {
        assertion = config.age != null;
        message = "age is not enabled";
      }
    ];

    # todo: add gpg signing
    programs.git = {
      enable = true;
      userName = "jo";
      userEmail = "lyra95@shiftup.co.kr";

      aliases = {
        # Prettier `git log`
        lg = "log --color --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit";
        rb = "rebase --interactive";
        last = "show HEAD";
        oops = "commit -a --amend --no-edit";
        fp = "push --force";
        pu = "!git push --set-upstream origin \"$(git rev-parse --abbrev-ref HEAD)\"";
        ig = "!vim \"$(git rev-parse --show-toplevel)/.gitignore\"";
        gc-all = "gc -q --prune --aggressive --keep-largest-pack --force";
      };

      delta = {
        enable = true;
        options = {
          navigate = true;
          line-numbers = true;
          hyperlinks = true;
          side-by-side = true;
          colorMoved = "default";
        };
      };

      extraConfig = {
        init.defaultBranch = "main";
        merge.conflictstyle = "diff3";
      };
    };

    age.secrets.github_ed25519 = {
      file = ./github_ed25519.age;
    };

    programs.ssh = {
      enable = true;
      extraConfig = ''
        Host github.com
                User jo
                HostName github.com
                PreferredAuthentications publickey
                IdentityFile ${config.age.secrets.github_ed25519.path}
      '';
    };
  };
}
