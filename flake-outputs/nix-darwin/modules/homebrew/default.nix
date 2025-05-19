profile: inputs: {
  imports = [
    (import ./homebrew.nix profile inputs)
    (import ./apps.nix)
  ];
}
