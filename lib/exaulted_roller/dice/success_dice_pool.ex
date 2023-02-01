defmodule ExaultedRoller.Dice.SuccessDicePool do
  defstruct dice: 1, success: [7, 8, 9, 10], double: [10], stunt: 0, wound: 0, reroll_once: [], reroll_none: []
  @type t :: %__MODULE__{dice: pos_integer | nil, success: [1..10], double: [1..10], stunt: 0..3, wound: -4..0, reroll_once: [1..10], reroll_none: [1..10]}

  import Ecto.Changeset

  @spec create(Map.t()) :: {:ok, __MODULE__.t()} | {:error, Ecto.Changeset.t()}
  def create(%{} = attrs) do
    %__MODULE__{}
    |> changeset(attrs)
    |> Ecto.Changeset.apply_action(:insert)
  end

  @spec changeset(__MODULE__.t(), Map.t()) :: Ecto.Changeset.t()
  def changeset(%__MODULE__{} = table, attrs) do
    {table, %{dice: :integer, success: {:array, :integer}, double: {:array, :integer}, stunt: :integer, wound: :integer, reroll_once: {:array, :integer}, reroll_none: {:array, :integer}}}
    |> cast(attrs, [:dice, :success, :double, :stunt, :wound, :reroll_once, :reroll_none ])
    |> validate_required([:dice])
    |> validate_number(:dice, greater_than: 0)
    |> validate_inclusion(:stunt, 0..3, message: "must be 0 through 3")
    |> validate_inclusion(:wound, -4..0, message: "must be -4 through 0")
    |> validate_subset(:success, 1..10, message: "must contain only 1 through 10")
    |> validate_clearable_subset(:double, 1..10, message: "must contain only 1 through 10")
    |> validate_clearable_subset(:reroll_once, 1..10, message: "must contain only 1 through 10")
    |> validate_clearable_subset(:reroll_none, 1..10, message: "must contain only 1 through 10")
  end

  defp validate_clearable_subset(changeset, field, criteria, opts) do
    case Map.get(changeset, :changes) do
      [""] ->
        %{changeset | changes: Map.put(changeset.changes, field, [])}

      [_] ->
        validate_subset(changeset, field, criteria, opts)

      _ ->
        changeset
    end
  end
end
