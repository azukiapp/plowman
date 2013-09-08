# Plowman - SSH-to-Git Server for Openruko

[![Build Status](https://travis-ci.org/azukiapp/plowman.png?branch=master)](https://travis-ci.org/azukiapp/plowman)

This is a alternative port of [gitmouth](https://github.com/openruko/gitmouth) written in [Elixir](http://elixir-lang.org)

# Introduction

`plowman` is a small SSH server written in Elixir/Erlang using the crypto ssh framework to handle git push and pull commands users make to manage their remote git repositories. It authenticates the user by matching their public key fingerprint against the API server database, then asks the API server to provision a dyno (a virtualization container) with the respective git repository mounted, finally it connects to this dyno over an SSH-like protocol and runs the git-receive-pack or git- upload-pack command, which in turn will execute the buildpack via git hooks.

For those not familiar with Heroku infrastructure, as buildpacks can contain potentially dangerous code the git command has to run inside an isolated dyno too, hence gogit is simply a bridge from the ssh transport to where the git commands run inside a dyno, authenticating and authorizing the request in the pipeline.

# Requirements

Tested on Mac OX 10.8.3 with Erlang R16B and Ubuntu Procise with Erlang R16B.

On Mac OS X use [kerl](https://github.com/spawngrid/kerl).
On Ubuntu using [Erlang Solutions](https://www.erlang-solutions.com/downloads/download-erlang-otp).

# Installation

```bash
$ git clone https://github.com/azukiapp/plowman.git
$ cd plowman
$ make # If not have elixir install this in deps/elixir
$ make certs
```

If you receive `terminated with reason: {'module could not be loaded',[{'Elixir-JSON',parse` error, try this:

```bash
$ cd deps/exjson
$ PATH=../elixir/bin make clean
$ PATH=../elixir/bin make
```

# Environment Variables

`plowman` will check for the presence of several environment variables, these must be configured as part of the process start.

- APISERVER_HOST - https andress to acess api server api. Example: APISERVER_HOST=https://mymachine.me:5000
- APISERVER_KEY  - special key to authenticate with API server. Example: APISERVER_KEY=abcdef-342131-123123123-asdasd

- DYNOHOST_PORT  - port to connect dynhost build instances. Example: DYNOHOST_PORT=4000

- PLOWMAN_PORT      - port to plowman listen ssh/git connections. Example: PLOWMAN_PORT=2222
- PLOWMAN_HOST      - host andress to plowman listen ssh/git connections. Example: PLOWMAN_HOST=0.0.0.0
- PLOWMAN_HOST_KEYS - folder with private/public rsa host keys. Example: PLOWMAN_HOST_KEYS=./certs

# License

plwoman are licensed under MIT. http://opensource.org/licenses/mit-license.php


[![Bitdeli Badge](https://d2weczhvl823v0.cloudfront.net/azukiapp/plowman/trend.png)](https://bitdeli.com/free "Bitdeli Badge")

