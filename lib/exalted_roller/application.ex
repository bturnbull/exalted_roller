defmodule ExaltedRoller.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Telemetry supervisor
      ExaltedRollerWeb.Telemetry,
      # Start the Ecto repository
      # ExaltedRoller.Repo,
      # Start the PubSub system
      {Phoenix.PubSub, name: ExaltedRoller.PubSub},
      ExaltedRollerWeb.Presence,
      # Start the Endpoint (http/https)
      ExaltedRollerWeb.Endpoint,
      # Start a worker by calling: ExaltedRoller.Worker.start_link(arg)
      # {ExaltedRoller.Worker, arg}
      ExaltedRoller.Tables.StorageSupervisor
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: ExaltedRoller.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    ExaltedRollerWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
