
PATH := $(PATH):./deps/elixir/bin

build: ebin/plowman.app

deps/elixir/ebin/elixir.app : 
	./rebar --config rebar.conf get-deps
	./rebar --config rebar.conf compile

mix: deps/elixir/ebin/elixir.app

ebin/plowman.app: mix
	mix

certs:
	mix certs

test:
	@MIX_ENV=test mix test

clean:
	rm -Rf ebin

.PHONY: clean test certs
