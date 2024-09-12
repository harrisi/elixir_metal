defmodule ElixirMetal.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Starts a worker by calling: ElixirMetal.Worker.start_link(arg)
      ElixirMetal.Window
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: ElixirMetal.Supervisor, auto_shutdown: :any_significant]
    Supervisor.start_link(children, opts)
  end
end
