# BemedaPersonal

## Setup

- install [Git LFS](https://git-lfs.github.com) and clone the repo using `git clone --recurse-submodules https://github.com/3Stones-IO/bemeda_personal.git`
  - if you've already cloned the repo without submodules, run `git submodule update --init`
  - to update submodules, run `git submodule foreach "git checkout main && git pull"`
- install Elixir, Erlang and Node using [mise](https://mise.jdx.dev)
  - install mise using either `curl https://mise.run | sh` or `brew install mise`
  - make sure to activate it
  - run `mise install`
- install MCP Proxy if you're using Tidewave (https://elixirdrops.net/d/UAo4BtYi)
  - `curl -sL https://github.com/tidewave-ai/mcp_proxy_rust/releases/latest/download/mcp-proxy-aarch64-apple-darwin.tar.gz | tar xv`
  - `sudo mv mcp-proxy /usr/local/bin`
- install LibreOffice using `brew install libreoffice`
- start PostgreSQL server
- run `mix setup`
- start Phoenix server with `mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

## Docs

- execute `mix docs --formatter html --open`

It will open documentation in your browser.

## Running tests

- run `mix coveralls` or `mix coveralls.html`

## Contributing

Make sure to execute `make check_code` in order to run all the checks before committing the code.
