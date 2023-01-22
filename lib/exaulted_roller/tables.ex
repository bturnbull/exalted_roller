defmodule ExaultedRoller.Tables do

  alias ExaultedRoller.Tables
  alias ExaultedRoller.Tables.Table

  @spec create() :: Table.t() | nil
  def create() do
    case Table.create(%{}) do
      {:ok, table} ->
        Tables.StorageWorker.create_table(table)

      _ ->
        nil
    end
  end

  @spec join(uid: String.t()) :: Table.t() | nil
  def join(uid: uid) do
    case Tables.StorageWorker.get_table(uid) do
      %Table{} = table ->
        table

      _ ->
        nil
    end
  end

  @spec add_roll(Table.t(), []) :: Table.t() | nil
  def add_roll(%Table{} = table, roll) when is_list(roll) do
    Tables.StorageWorker.add_roll(table, roll)
  end
end
