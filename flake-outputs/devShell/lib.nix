nixpkgs: let
  lib = nixpkgs.lib;
  allSystems = ["x86_64-linux" "aarch64-darwin"];
in {
  mkFlakeOutput = output: let
    attributes = [
      "checks"
      "formatter"
      "devShells"
    ];
  in
    lib.genAttrs
    attributes
    (topLevelAttr:
      lib.genAttrs allSystems (system: (output system).${topLevelAttr}));
}
