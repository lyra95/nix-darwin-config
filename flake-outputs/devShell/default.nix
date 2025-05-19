inputs @ {nixpkgs, ...}: let
  mkFlakeOutput = (import ./lib.nix nixpkgs).mkFlakeOutput;
in
  mkFlakeOutput (import ./output.nix inputs)
