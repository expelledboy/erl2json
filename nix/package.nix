{ pkgs, self, buildRebar3 }:

let
  version =
    if self ? shortRev
    then
      "${self.lastModifiedDate}-${self.shortRev}"
    else
      "${self.lastModifiedDate}-dirty";
in
buildRebar3 {
  name = "erl2json";
  inherit version;
  src = self;
  beamDeps = [ ];
  buildPhase = ''
    rebar3 escriptize
  '';
  installPhase = ''
    mkdir -p $out/bin
    install _build/default/bin/erl2json $out/bin
  '';
}
