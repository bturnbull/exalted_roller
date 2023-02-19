defmodule ExaltedRoller.Tables.StorageWorker do
  use GenServer

  require Logger

  @active_table_max 100
  @table_rolls_max 20

  alias ExaltedRoller.Tables

  def start_link(args \\ []) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  def get_table(%Tables.Table{} = table) do
    get_table(table.uid)
  end

  def get_table(uid) do
    GenServer.call(__MODULE__, {:get_table, uid})
  end

  def set_table(%Tables.Table{} = table) do
    GenServer.call(__MODULE__, {:set_table, table})
  end

  def create_table(%Tables.Table{} = table) do
    GenServer.call(__MODULE__, {:create_table, table})
  end

  def add_roll(%Tables.Table{} = table, player, roll) do
    GenServer.call(__MODULE__, {:add_roll, table, player, roll})
  end

  def get_latest_roll(%Tables.Table{} = table, player) do
    GenServer.call(__MODULE__, {:get_latest_roll, table, player})
  end

  @impl true
  def init(_args) do
    :ets.new(__MODULE__, [:named_table])

    {:ok, %{active_uids: []}}
  end

  @impl true
  def handle_call({:get_table, uid}, _from, state) do
    case :ets.lookup(__MODULE__, uid) do
      [{^uid, table}] ->
        {:reply, table, state}

      [] ->
        {:reply, nil, state}
    end
  end

  @impl true
  def handle_call({:set_table, table}, _from, state) do
    :ets.insert(__MODULE__, {table.uid, table})

    {:reply, table, state}
  end

  @impl true
  def handle_call({:create_table, table}, _from, state) do
    case :ets.lookup(__MODULE__, table.uid) do
      [] ->
        :ets.insert(__MODULE__, {table.uid, table})

        {:reply, table, state, {:continue, {:reaper, table.uid}}}

      [{_, _}] ->
        {:reply, nil, state}
    end
  end

  @impl true
  def handle_call({:add_roll, table, player, roll}, _from, state) do
    uid = table.uid

    case :ets.lookup(__MODULE__, uid) do
      [{^uid, table}] ->
        table = %{table | rolls: [{player, roll} | Enum.slice(table.rolls, 0..(@table_rolls_max - 2))]}
        :ets.insert(__MODULE__, {table.uid, table})

        {:reply, table, state, {:continue, {:reaper, table.uid}}}

      [] ->
        {:reply, nil, state}
    end
  end

  @impl true
  def handle_call({:get_latest_roll, table, player}, _from, state) do
    uid = table.uid

    case :ets.lookup(__MODULE__, uid) do
      [{^uid, table}] ->
        {:reply, latest_roll(table, player), state}

      _ ->
        {:reply, nil, state}
    end
  end

  @impl true
  def handle_continue({:reaper, uid}, state) do
    active_uids =
      Enum.uniq([uid | state.active_uids])
      |> reap_stale_tables()

    {:noreply, %{state | active_uids: active_uids}}
  end

  defp latest_roll(table, player) do
    case Enum.find(table.rolls, [], fn {p, _} -> p == player end) do
      {_, roll} ->
        roll

      _ ->
        nil
    end
  end

  defp reap_stale_tables(active_uids) do
    if length(active_uids) <= @active_table_max do
      active_uids
    else
      {uid, active_uids} = List.pop_at(active_uids, -1)
      Logger.warn("Table.StorageWorker: Reaping table #{uid}")
      :ets.delete(__MODULE__, uid)

      reap_stale_tables(active_uids)
    end
  end
end
