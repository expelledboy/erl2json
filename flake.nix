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
        inCI = builtins.getEnv "CI" != "";
      in
      rec {
        packages.erl2json = beamPkgs.callPackage ./nix/package.nix { inherit self; };

        packages.default = packages.erl2json;

        devShell = pkgs.mkShell {
          buildInputs = with pkgs; with beamPkgs; [
            just
            bats
            rebar3
            erlang
            nixpkgs-fmt
            packages.default
          ] ++ (pkgs.lib.lists.optionals (!inCI) [
            act
            erlang-ls
          ]);

          shellHook = ''
            git config --local core.hooksPath .github/hooks
          '';
        };
      }
    );
}
