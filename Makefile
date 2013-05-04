
# Set env
root_dir:= $(shell pwd)
erl_dir := $(shell dirname `which erl`)
PATH := $(erl_dir):/bin:/usr/bin:$(root_dir)/deps/elixir/bin:$(root_dir)/bin

build: ebin/plowman.app

silence_compiled = grep -v '^[Compiled|Compiling]'

deps/elixir/ebin/elixir.app :
	@echo "\x1b[1;32mGet Elixir...\x1b[0m"
	rebar --config rebar.conf get-deps
	rebar --config rebar.conf compile | $(silence_compiled)
	@echo

mix: deps/elixir/ebin/elixir.app

deps-test: mix
	@MIX_ENV=test mix deps.get | $(silence_compiled)

deps: mix
	@mix deps.get | $(silence_compiled)

ebin/plowman.app: deps
	@echo "\x1b[1;32mCompile plowman...\x1b[0m"
	mix

certs:
	mix certs

test: deps-test
	@MIX_ENV=test mix test

clean:
	rm -Rf ebin

.PHONY: clean test certs
