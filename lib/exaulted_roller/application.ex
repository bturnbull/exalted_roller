defmodule ExaultedRoller.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Telemetry supervisor
      ExaultedRollerWeb.Telemetry,
      # Start the Ecto repository
      # ExaultedRoller.Repo,
      # Start the PubSub system
      {Phoenix.PubSub, name: ExaultedRoller.PubSub},
      # Start the Endpoint (http/https)
      ExaultedRollerWeb.Endpoint,
      # Start a worker by calling: ExaultedRoller.Worker.start_link(arg)
      # {ExaultedRoller.Worker, arg}
      ExaultedRoller.Tables.StorageSupervisor
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: ExaultedRoller.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    ExaultedRollerWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
