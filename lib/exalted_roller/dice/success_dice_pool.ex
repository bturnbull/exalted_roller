defmodule ExaltedRoller.Dice.SuccessDicePool do
  defstruct dice: 1, label: nil, success: [7, 8, 9, 10], double: [10], stunt: 0, wound: 0, auto: 0, reroll_once: [], reroll_none: []
  @type t :: %__MODULE__{dice: pos_integer | nil, label: String.t() | nil, success: [1..10], double: [1..10], stunt: 0..3, wound: -4..0, auto: non_neg_integer, reroll_once: [1..10], reroll_none: [1..10]}

  import Ecto.Changeset

  @spec create(Map.t()) :: {:ok, __MODULE__.t()} | {:error, Ecto.Changeset.t()}
  def create(%{} = attrs) do
    %__MODULE__{}
    |> changeset(attrs)
    |> Ecto.Changeset.apply_action(:insert)
  end

  @spec changeset(__MODULE__.t(), Map.t()) :: Ecto.Changeset.t()
  def changeset(%__MODULE__{} = table, attrs) do
    {table, %{dice: :integer, label: :string, success: {:array, :integer}, double: {:array, :integer}, stunt: :integer, wound: :integer, auto: :integer, reroll_once: {:array, :integer}, reroll_none: {:array, :integer}}}
    |> cast(attrs, [:dice, :label, :success, :double, :stunt, :wound, :auto, :reroll_once, :reroll_none ])
    |> validate_required([:dice])
    |> validate_number(:dice, greater_than: 0)
    |> validate_number(:dice, less_than: 100)
    |> validate_number(:auto, greater_than_or_equal_to: 0)
    |> validate_inclusion(:stunt, 0..3, message: "must be 0 through 3")
    |> validate_inclusion(:wound, -4..0, message: "must be -4 through 0")
    |> validate_subset(:success, 1..10, message: "must contain only 1 through 10")
    |> validate_clearable_subset(:double, 1..10, message: "must contain only 1 through 10")
    |> validate_clearable_subset(:reroll_once, 1..10, message: "must contain only 1 through 10")
    |> validate_clearable_subset(:reroll_none, 1..10, message: "must contain only 1 through 10")
    |> validate_reroll_safe(:reroll_none, 1..10, message: "must not contain all values")
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

  defp validate_reroll_safe(changeset, field, criteria, opts) do
    case fetch_change(changeset, field) do
      {:ok, change} ->
        if Enum.sort(Enum.to_list(criteria)) == Enum.sort(change) do
          add_error(changeset, field, Keyword.get(opts, :message, "invalid"))
        else
          changeset
        end

      :error ->
        changeset
    end
  end
end
