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
	rebar3 fmt --write

ci: && bats coverage
	rebar3 fmt --check
