defmodule Plowman.Mixfile do
  use Mix.Project

  def project do
    [ app: :plowman,
      version: "0.0.1",
      deps: deps ]
  end

  # Configuration for the OTP application
  def application do
    []
  end

  # Returns the list of dependencies in the format:
  # { :foobar, "0.1", git: "https://github.com/elixir-lang/foobar.git" }
  defp deps do
    [
      {:mimetypes,"1.0",[github: "spawngrid/mimetypes", tag: "1.0"]},
      {:hackney,"0.4.0",[github: "benoitc/hackney", tag: "0.4.0"]}
    ]
  end
end
