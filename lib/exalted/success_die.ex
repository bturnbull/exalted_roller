defmodule Exalted.SuccessDie do
  @moduledoc """
  An Exalted 3E success die.

  Can be rolled multiple times maintaining a history of all rolls.  Prevent
  further rolls from modifying the die using `freeze\0`.
  """

  @sides 10

  defstruct value: nil, history: [], frozen: false

  @type t :: %__MODULE__{
          value: nil | atom | pos_integer,
          history: [tuple],
          frozen: boolean
        }

  @doc """
  Create a new `ExaltedRoller.SuccessDie` struct and roll it with reason "Initial".

  Returns `%ExaltedRoller.SuccessDie{}`.

  ## Examples

      iex> die = ExaltedRoller.SuccessDie.create()
      %ExaltedRoller.SuccessDie{value: 1, history: [{1, "Initial"}], frozen: false}

  """
  @spec create() :: __MODULE__.t()
  def create() do
    %__MODULE__{}
    |> roll("Initial")
  end

  @doc """
  Roll an `ExaltedRoller.SuccessDie` struct replacing the current value.

  If `freeze/0` has been called, will return the current struct unmodified.

  Returns `%ExaltedRoller.SuccessDie{}`

  ## Examples

      iex> ExaltedRoller.SuccessDie.create()
      ...> |> ExaltedRoller.SuccessDie.roll("Reroll")
      %ExaltedRoller.SuccessDie{value: 4, history: [{4, "Reroll"}, {1, "Initial"}, frozen: false}

  """
  @spec roll(__MODULE__.t(), String.t()) :: __MODULE__.t()
  def roll(%__MODULE__{frozen: true} = die, _reason) do
    die
  end

  def roll(%__MODULE__{} = die, reason) when is_binary(reason) do
    result = :rand.uniform(@sides)
    %{die | value: result, history: [{result, reason} | die.history]}
  end

  @doc """
  Freeze an `ExaltedRoller.SuccessDie` struct to prevent it being rolled.

  Returns `%ExaltedRoller.SuccessDie{}`

  ## Examples

      iex> ExaltedRoller.SuccessDie.create()
      ...> |> ExaltedRoller.SuccessDie.freeze()
      ...> |> ExaltedRoller.SuccessDie.roll("Reroll")
      %ExaltedRoller.SuccessDie{value: 1, history: [{1, "Initial"}], frozen: true}

  """
  @spec freeze(__MODULE__.t()) :: __MODULE__.t()
  def freeze(%__MODULE__{} = die) do
    %{die | frozen: true}
  end
end
