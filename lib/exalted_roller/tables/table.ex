defmodule ExaultedRoller.Tables.Table do
  defstruct uid: nil, rolls: []
  @type t :: %__MODULE__{uid: String.t() | nil, rolls: []}

  import Ecto.Changeset

  @spec create(Map.t()) :: {:ok, __MODULE__.t()} | {:error, Ecto.Changeset.t()}
  def create(%{} = attrs) do
    %__MODULE__{uid: generate_uid()}
    |> changeset(attrs)
    |> Ecto.Changeset.apply_action(:insert)
  end

  @spec changeset(__MODULE__.t(), Map.t()) :: Ecto.Changeset.t()
  def changeset(%__MODULE__{} = table, attrs) do
    {table, %{uid: :string}}
    |> cast(attrs, [:uid])
    |> validate_required([:uid])
  end

  @doc false
  @spec generate_uid() :: String.t()
  defp generate_uid() do
    Ecto.UUID.generate()
    |> String.split("-")
    |> List.first()
    |> String.upcase()
  end
end
