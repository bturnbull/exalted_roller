defmodule ExaltedRoller.Players do

  alias ExaltedRoller.Players.Player

  @spec create(name: String.t(), character: String.t()) :: Player.t() | nil
  def create(name: name, character: character) do
    case Player.create(%{name: name, character: character}) do
      {:ok, player} ->
        player

      _ ->
        nil
    end
  end
end
