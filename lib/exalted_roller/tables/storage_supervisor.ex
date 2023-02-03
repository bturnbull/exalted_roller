defmodule ExaltedRoller.Tables.StorageSupervisor do
  use Supervisor

  alias ExaltedRoller.Tables

  def start_link(args \\ []) do
    Supervisor.start_link(__MODULE__, args, name: __MODULE__)
  end

  @impl true
  def init(_args) do
    children = [
      Tables.StorageWorker
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
