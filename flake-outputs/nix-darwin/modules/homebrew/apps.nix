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
        "stirling-pdf"
      ]
      ++ work;

    brews = [
      "podman"
    ];

    masApps = {
      "KakaoTalk" = 869223134;
    };
  };
}
