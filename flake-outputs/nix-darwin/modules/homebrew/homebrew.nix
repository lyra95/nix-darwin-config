profile @ {userName, ...}: inputs @ {
  nix-homebrew,
  homebrew-core,
  homebrew-cask,
  ...
}: {
  imports = [
    nix-homebrew.darwinModules.nix-homebrew
  ];

  nix-homebrew = {
    enable = true;
    user = userName;
    taps = {
      "homebrew/homebrew-core" = homebrew-core;
      "homebrew/homebrew-cask" = homebrew-cask;
    };
    mutableTaps = false;
    autoMigrate = true;
  };
  homebrew.enable = true;
}
