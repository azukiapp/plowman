defmodule Plowman.Mixfile do
  use Mix.Project

  def project do
    [ app: :plowman,
      version: "0.0.1",
      deps: deps ]
  end

  # Configuration for the OTP application
  def application do
    [
      applications: [:crypto, :public_key, :ssl, :ssh, :hackney, :lager],
      env: [
        binding: '0.0.0.0',
        port: 3333,
        host_keys: '/Users/nuxlli/Downloads/egit/certs',
        api_server: [
          host: "https://mymachine.me:5000",
          key: "ec1a8eb9-18a6-42c2-81ec-c0f0f615280c"
        ],
        dynohost: [
          rendezvous_port: 4000
        ],
      ]
    ]
  end

  # Returns the list of dependencies in the format:
  # { :foobar, "0.1", git: "https://github.com/elixir-lang/foobar.git" }
  defp deps do
    [
      {:mimetypes, "1.0"  , [github: "spawngrid/mimetypes", tag: "1.0"]},
      {:hackney  , "0.4.0", [github: "benoitc/hackney", tag: "0.4.0"]},
      {:meck     , "0.7.2", [github: "eproxus/meck", branch: "develop"]},
      {:uuid     , "0.4.3", [github: "avtobiff/erlang-uuid", branch: "master"]},
      {:exjson   , "0.0.1", [github: "azukiapp/exjson", branch: "master"]},
      {:goldrush , "0.1.0", [github: "DeadZen/goldrush", tag: "7ff9b03"]},
      {:lager    , "2.0.0", [github: "basho/lager", tag: "2.0.0rc2"]}
    ]
  end
end
