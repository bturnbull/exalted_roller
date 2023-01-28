defmodule ExaultedRoller.Tables do

  alias Exaulted.SuccessDicePool
  alias ExaultedRoller.Tables
  alias ExaultedRoller.Tables.Table
  alias ExaultedRoller.Players.Player

  @spec create() :: Table.t() | nil
  def create() do
    case Table.create(%{}) do
      {:ok, table} ->
        Tables.StorageWorker.create_table(table)

      _ ->
        nil
    end
  end

  @spec fetch(Table.t()) :: Table.t() | nil
  @spec fetch(String.t()) :: Table.t() | nil
  def fetch(nil), do: nil

  def fetch(%Table{uid: uid} = _table) do
    fetch(uid)
  end

  def fetch(uid) do
    case Tables.StorageWorker.get_table(uid) do
      %Table{} = table ->
        table

      _ ->
        nil
    end
  end

  @spec add_roll(Table.t(), Player.t(), SuccessDicePool.t()) :: Table.t() | nil
  def add_roll(%Table{} = table, %Player{} = player, %SuccessDicePool{} = pool) do
    Tables.StorageWorker.add_roll(table, player, pool)
  end
end
