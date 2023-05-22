build:
	rebar3 escriptize

test:
	rebar3 do eunit --cover, cover --verbose

lint:
	rebar3 fmt --write
