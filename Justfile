build:
	rebar3 escriptize

test: build
	bats test/*.bats
	rebar3 do eunit --cover, cover --verbose

lint:
	rebar3 fmt --write
