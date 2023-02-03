defmodule ExaltedRoller.Tables do

  alias Exalted.SuccessDicePool
  alias ExaltedRoller.Tables
  alias ExaltedRoller.Tables.Table
  alias ExaltedRoller.Players.Player

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

  @spec get_latest_roll(Table.t(), Player.t()) :: SuccessDicePool.t() | nil
  def get_latest_roll(%Table{} = table, %Player{} = player) do
    Tables.StorageWorker.get_latest_roll(table, player)
  end
end
