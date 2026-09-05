{
  homebrew = {
    # things that are system-wide or difficult to be managed by nix
    casks = let
      work = [
        "p4v"
        "unity-hub"
        "slack"
      ];
    in
      [
        "wezterm"
        "visual-studio-code"
        "firefox"
        "1password"
        "tailscale-app"
        "jetbrains-toolbox"
        "podman-desktop"
        "steam"
        "parsec"
        "fork"
        "obsidian"
        "cloudflare-warp"
        "spotify"
        "libreoffice"
        "anki"
        "discord"
        "claude-code"
      ]
      ++ work;

    brews = [];

    # how to get id: mas search "KakaoTalk"
    masApps = {
      "KakaoTalk" = 869223134;
      "Line" = 539883307;
    };
  };
}
