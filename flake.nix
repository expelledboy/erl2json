{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-22.11";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        beamPkgs = pkgs.beam.packagesWith pkgs.beam.interpreters.erlangR23;
      in
      rec {
        defaultPackage = beamPkgs.callPackage
          ./nix/package.nix
          { inherit self; };
        packages = flake-utils.lib.flattenTree {
          erl2json = defaultPackage;
        };
        devShell = pkgs.mkShell {
          buildInputs = with pkgs; with beamPkgs; [
            defaultPackage
            just
            bats
            rebar3
            erlang
            erlang-ls
          ];
        };
      }
    );
}
