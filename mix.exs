Code.require_file "../Mixfile", __FILE__

defmodule Plowman.Mixfile do
  use Mix.Project

  @path [
    dev: "ebin", prod: "ebin", test: "ebin/test"
  ]

  def project do
    [ app: :plowman,
      version: "0.0.1",
      deps: deps(Mix.env),
      elixirc_options: options(Mix.env),
      compile_path: @path[Mix.env]
    ]
  end

  # Configuration for the OTP application
  def application do
    application(Mix.env) ++ [
      env: [
        binding: '0.0.0.0',
        port: 3333,
        host_keys: './certs',
        api_server_host: "https://mymachine.me:5000",
        api_server_key: "ec1a8eb9-18a6-42c2-81ec-c0f0f615280c",
        dynohost_rendezvous_port: 4000
      ]
    ]
  end

  defp application(:test) do
    [
      applications: [:exlager]
    ]
  end

  defp application(env) when env in [:dev, :prod] do
    [
      registered: [:plowman],
      applications: [:crypto, :public_key, :ssl, :ssh, :hackney, :exlager],
      mod: {Plowman, []},
    ]
  end

  defp options(env) when env in [:dev, :test] do
    [exlager_level: :debug, exlager_truncation_size: 8096]
  end

  defp options(:prod) do
    []
  end

  # Returns the list of dependencies in the format:
  defp deps(:test) do
    deps(:prod) ++ [
      {:meck     , "0.7.2", [github: "eproxus/meck", branch: "develop"]},
    ]
  end

  defp deps(env) when env in [:dev, :prod] do
    [
      {:mimetypes, "1.0"  , [github: "spawngrid/mimetypes", tag: "1.0"]},
      {:hackney  , "0.4.0", [github: "benoitc/hackney", tag: "0.4.0"]},
      {:uuid     , "0.4.4", [github: "avtobiff/erlang-uuid", tag: "v0.4.4"]},
      {:exjson   , "0.0.1", [github: "azukiapp/exjson", branch: "master"]},
      {:exlager  , "0.2.1", [github: "khia/exlager", branch: "master"]},
      {:goldrush , "0.1.0", [github: "DeadZen/goldrush", tag: "7ff9b03"]},
    ]
  end
end
