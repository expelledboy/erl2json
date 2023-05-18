{ pkgs ? import <nixpkgs> { } }:

pkgs.mkShell {
  buildInputs = with pkgs; [
    just
    bats
    rebar3
    erlang
    erlang-ls
  ];
}

