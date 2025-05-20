let
  keys = import ../../../../publicKeys.nix;
in {
  "github_ed25519.age".publicKeys = [keys.lyra95];
}
