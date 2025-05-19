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
        "tailscale"
        "jetbrains-toolbox"
        "podman-desktop"
        "steam"
        "parsec"
      ]
      ++ work;

    masApps = {
      "KakaoTalk" = 869223134;
    };
  };
}
