defmodule ExaultedRoller.Tables do

  def create_or_join(uid: nil), do: create()

  def create_or_join(uid: ""), do: create()

  def create_or_join(uid: uid) when is_binary(uid) do
    %{uid: uid}  # %Table{}
  end

  def create() do
    %{uid: generate_uid()}
  end

  @doc false
  defp generate_uid() do
    Ecto.UUID.generate()
    |> String.split("-")
    |> List.first()
    |> String.upcase()
  end
end
