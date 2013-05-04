
PATH := $(PATH):./deps/elixir/bin

build: ebin/plowman.app

deps/elixir/ebin/elixir.app : 
	./rebar --config rebar.conf get-deps
	./rebar --config rebar.conf compile

ebin/plowman.app: deps/elixir/ebin/elixir.app
	mix

test:
	@MIX_ENV=test mix test

clean:
	rm -Rf ebin

.PHONY: clean test
