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
      applications: [:crypto, :public_key, :ssl, :ssh, :hackney],
      env: [
        port: 3333,
        api_server: [
          host: "https://mymachine.me:5000",
          key: "ec1a8eb9-18a6-42c2-81ec-c0f0f615280c"
        ]
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
      {:uuid     , "0.4.3", [github: "avtobiff/erlang-uuid", branch: "master"]}
    ]
  end
end
