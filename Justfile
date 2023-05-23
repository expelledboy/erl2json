build:
	rebar3 escriptize

eunit:
	rebar3 eunit

bats: build
	bats test/*.bats

test: eunit bats

coverage:
	rebar3 eunit -c
	rebar3 cover -v

lint:
	rebar3 fmt --check
	nixpkgs-fmt --check flake.nix nix/*.nix

ci: bats coverage lint

ci-test:
	act push

quick-test: build
	nix run . < examples/readme.erl | jq -c '{ test: .record }'

pre-commit: lint

pre-push: quick-test
