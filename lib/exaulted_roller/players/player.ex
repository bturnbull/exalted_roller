defmodule ExaultedRoller.Players.Player do
  defstruct name: nil, character: nil
  @type t :: %__MODULE__{name: String.t() | nil, character: String.t() | nil}

  import Ecto.Changeset

  @spec create(Map.t()) :: {:ok, __MODULE__.t()} | {:error, Ecto.Changeset.t()}
  def create(%{} = attrs) do
    %__MODULE__{}
    |> changeset(attrs)
    |> Ecto.Changeset.apply_action(:insert)
  end

  @spec changeset(__MODULE__.t(), Map.t()) :: Ecto.Changeset.t()
  def changeset(%__MODULE__{} = player, attrs) do
    {player, %{name: :string, character: :string}}
    |> cast(attrs, [:name, :character])
    |> validate_required([:name, :character])
  end
end
