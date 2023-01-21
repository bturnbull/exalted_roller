defmodule ExaultedRoller.Players do

  def create(name: name, character: character) do
    if is_nil(name) or is_nil(character) do
      nil
    else
      %{name: name, character: character}  # %Player{}
    end
  end
end
