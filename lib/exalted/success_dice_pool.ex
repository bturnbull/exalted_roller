defmodule Exalted.SuccessDicePool do
  @moduledoc """
  A pool of Exalted 3E success dice.
  """

  @default_success [7, 8, 9, 10]
  @default_double [10]

  alias Exalted.SuccessDie

  defstruct dice: [], label: nil, success: @default_success, double: @default_double, stunt: 0, wound: 0, auto: 0

  @type t :: %__MODULE__{
          dice: [SuccessDie.t()],
          label: String.t() | nil,
          success: [1..10],
          double: [1..10],
          stunt: 0..3,
          wound: -4..0,
          auto: non_neg_integer()
        }

  @doc """
  Create a new `ExaltedRoller.SuccessDicePool` with `count` dice.

  Will count successes on 7, 8, 9, and 10 and double successes on 10.  See
  keyword arguments below to override.

  Keyword arguments:

    * `:success` - List of integers that represent success.
    * `:double` - List of integers that represent double success.
    * `:stunt` - The stunt level for this pool.
    * `:wound` - The wound penalty for this pool.
    * `:auto` - Automatic success count (not including stunt)

  ## Examples

      iex> ExaltedRoller.SuccessDicePool.create(3)
      %ExaltedRoller.SuccessDicePool{
        dice: [
          %ExaltedRoller.SuccessDie{value: 10, history: [{10, "Initial"}], frozen: false},
          %ExaltedRoller.SuccessDie{value: 7, history: [{7, "Initial"}], frozen: false},
          %ExaltedRoller.SuccessDie{value: 3, history: [{3, "Initial"}], frozen: false}
        ],
        success: [7, 8, 9, 10],
        double: [10],
        stunt: 0,
        wound: 0,
        auto: 0
      }

      iex> ExaltedRoller.SuccessDicePool.create(3, double: [9, 10], stunt: 2, wound: -1, auto: 1)
      %ExaltedRoller.SuccessDicePool{
        dice: [
          %ExaltedRoller.SuccessDie{value: 1, history: [{1, "Initial"}], frozen: false},
          %ExaltedRoller.SuccessDie{value: 9, history: [{9, "Initial"}], frozen: false},
          %ExaltedRoller.SuccessDie{value: 10, history: [{10, "Initial"}], frozen: false},
          %ExaltedRoller.SuccessDie{value: 7, history: [{7, "Initial"}], frozen: false}
        ],
        success: [7, 8, 9, 10],
        double: [9, 10],
        stunt: 2,
        wound: -1,
        auto: 1
      }

  """
  @spec create(pos_integer()) :: __MODULE__.t()
  @spec create(pos_integer(), keyword()) :: __MODULE__.t()
  def create(count, kwargs \\ []) do
    struct(%__MODULE__{}, kwargs)
    |> roll(count)
  end

  @doc """
  Roll an `ExaltedRoller.SuccessDicePool` replacing the current dice result.

  If you having an existing struct, this will fully replace the dice pool.  Use
  it to start a dice pool over with existing configuration.  if no `count` is
  passed, roll same number of dice as the passed `pool`.

  Returns `%ExaltedRoller.SuccessDicePool{}`

  ## Examples

      # Roll 4 dice subtracting 2 for wound penalty
      iex> pool = ExaltedRoller.SuccessDicePool.create(4, wound: -2)
      %ExaltedRoller.SuccessDicePool{
        dice: [
          %ExaltedRoller.SuccessDie{value: 6, history: [{6, "Initial"}], frozen: false},
          %ExaltedRoller.SuccessDie{value: 1, history: [{1, "Initial"}], frozen: false}
        ],
        success: [7, 8, 9, 10],
        double: [10],
        stunt: 0,
        wound: -2,
        auto: 0
      }

      # Roll 4 dice subtracting 2 for wound penalty (same as above)
      iex> ExaltedRoller.SuccessDicePool.roll(pool)
      %ExaltedRoller.SuccessDicePool{
        dice: [
          %ExaltedRoller.SuccessDie{value: 7, history: [{7, "Initial"}], frozen: false},
          %ExaltedRoller.SuccessDie{value: 10, history: [{10, "Initial"}], frozen: false}
        ],
        success: [7, 8, 9, 10],
        double: [10],
        stunt: 0,
        wound: -2,
        auto: 0
      }

      # Roll 5 dice using the same config (wound of -2 subtracts 2 dice from pool)
      iex> ExaltedRoller.SuccessDicePool.roll(pool, 5)
      %ExaltedRoller.SuccessDicePool{
        dice: [
          %ExaltedRoller.SuccessDie{value: 8, history: [{8, "Initial"}], frozen: false},
          %ExaltedRoller.SuccessDie{value: 5, history: [{5, "Initial"}], frozen: false},
          %ExaltedRoller.SuccessDie{value: 2, history: [{2, "Initial"}], frozen: false}
        ],
        success: [7, 8, 9, 10],
        double: [10],
        stunt: 0,
        wound: -2,
        auto: 0
      }

  """
  @spec roll(__MODULE__.t(), pos_integer) :: __MODULE__.t()
  def roll(%__MODULE__{} = pool, count) when is_integer(count) do
    dice =
      for i <- 0..(count + wound_dice_penalty(pool) + stunt_dice_bonus(pool)),
          i > 0,
          do: SuccessDie.create()

    Map.put(pool, :dice, dice)
  end

  @spec roll(__MODULE__.t()) :: __MODULE__.t()
  def roll(%__MODULE__{} = pool) do
    dice = for i <- 0..length(pool.dice), i > 0, do: SuccessDie.create()

    Map.put(pool, :dice, dice)
  end

  @doc """
  Returns true if the struct represents a botched roll.

  ## Examples

      iex> pool = ExaltedRoller.SuccessDicePool.create(2)
      %ExaltedRoller.SuccessDicePool{
        dice: [
          %ExaltedRoller.SuccessDie{value: 6, history: [{6, "Initial"}], frozen: false},
          %ExaltedRoller.SuccessDie{value: 1, history: [{1, "Initial"}], frozen: false}
        ],
        success: [7, 8, 9, 10],
        double: [10],
        stunt: 0,
        wound: 0,
        auto: 0
      }

      iex> ExaltedRoller.SuccessDicePool.botch?(pool)
      true

  """
  @spec botch?(__MODULE__.t()) :: boolean
  def botch?(%__MODULE__{} = pool) do
    Enum.any?(pool.dice, &(&1.value == 1)) and
      success_count(pool) == 0
  end

  @doc """
  The number of successes in the pool.

  ## Examples

      iex> pool = ExaltedRoller.SuccessDicePool.create(2, stunt: 2, auto: 1)
      %ExaltedRoller.SuccessDicePool{
        dice: [
          %ExaltedRoller.SuccessDie{value: 10, history: [{10, "Initial"}], frozen: false},
          %ExaltedRoller.SuccessDie{value: 1, history: [{1, "Initial"}], frozen: false},
          %ExaltedRoller.SuccessDie{value: 7, history: [{7, "Initial"}], frozen: false},
          %ExaltedRoller.SuccessDie{value: 2, history: [{2, "Initial"}], frozen: false}
        ],
        success: [7, 8, 9, 10],
        double: [10],
        stunt: 2,
        wound: 0,
        auto: 1
      }

      # stunt: 2 adds an automatic success, 10s are doubled
      iex> ExaltedRoller.SuccessDicePool.success_count(pool)
      5

  """
  @spec success_count(__MODULE__.t()) :: non_neg_integer
  def success_count(%__MODULE__{} = pool) do
    Enum.count(pool.dice, &die_success?(pool, &1)) +
      Enum.count(pool.dice, &die_double?(pool, &1)) +
      reroll_success_count(pool) +
      automatic_success_count(pool)
  end

  @doc """
  The number of rerolled successes in the pool.

  Counts the number of dice that have been rerolled and were in the success set
  prior to being rerolled.  Dice in the double set count double.
  """
  @spec reroll_success_count(__MODULE__.t()) :: integer
  def reroll_success_count(%__MODULE__{} = pool) do
    successes =
      Stream.map(pool.dice, &(&1.history))        # die history tuples
      |> Enum.map(&(List.delete_at(&1, 0)))       # remove final die
      |> List.flatten()
      |> Stream.map(&(elem(&1, 0)))               # die history values
      |> Enum.filter(&(&1 in pool.success))       # keep only successes

    doubles = Enum.filter(successes, &(&1 in pool.double))

    length(successes) + length(doubles)
  end

  @doc """
  The number of automatic successes in the pool.

  ## Examples

      iex> pool = ExaltedRoller.SuccessDicePool.create(2, stunt: 2, auto: 1)
      %ExaltedRoller.SuccessDicePool{
        dice: [
          %ExaltedRoller.SuccessDie{value: 10, history: [{10, "Initial"}], frozen: false},
          %ExaltedRoller.SuccessDie{value: 1, history: [{1, "Initial"}], frozen: false},
          %ExaltedRoller.SuccessDie{value: 7, history: [{7, "Initial"}], frozen: false},
          %ExaltedRoller.SuccessDie{value: 2, history: [{2, "Initial"}], frozen: false}
        ],
        success: [7, 8, 9, 10],
        double: [10],
        stunt: 2,
        wound: 0,
        auto: 1
      }

      # stunt: 2 adds 1 automatic success
      iex> ExaltedRoller.SuccessDicePool.automatic_success_count(pool)
      2

  """
  @spec automatic_success_count(__MODULE__.t()) :: 0..2
  def automatic_success_count(%__MODULE__{} = pool) do
    max(pool.stunt - 1, 0) + pool.auto
  end

  @doc """
  Returns the number of success dice added to the pool by the stunt level.
  """
  @spec stunt_dice_bonus(__MODULE__.t()) :: 0 | 2
  def stunt_dice_bonus(%__MODULE__{} = pool) do
    case pool.stunt do
      stunt when stunt in 1..3 ->
        2

      _ ->
        0
    end
  end

  @doc """
  Returns the number of success dice removed from the pool by the wound level.
  """
  @spec wound_dice_penalty(__MODULE__.t()) :: -4..0
  def wound_dice_penalty(%__MODULE__{} = pool) do
    pool.wound
  end

  @doc """
  Returns true if the passed `ExaltedRoller.SuccessDie` represents a success.
  """
  @spec die_success?(__MODULE__.t(), SuccessDie.t()) :: boolean
  def die_success?(%__MODULE__{} = pool, %SuccessDie{} = die) do
    Enum.member?(pool.success, die.value)
  end

  @doc """
  Returns true if the passed `ExaltedRoller.SuccessDie` represents a double success.
  """
  @spec die_double?(__MODULE__.t(), SuccessDie.t()) :: boolean
  def die_double?(%__MODULE__{} = pool, %SuccessDie{} = die) do
    Enum.member?(pool.double, die.value)
  end

  @doc """
  Reroll a subset of the pool per Exalted 3E criteria.

  Criteria options:

    * `:not_success` - All dice that are not successes
    * `:not_10s` - All dice that are not tens
    * `[5, 6]` - All dice that are fives or sixes

  Count options:

    * `:once` - Roll the criteria one time
    * `:until_none` - Roll until criteria doesn't apply

  ## Examples

      iex> pool = ExaltedRoller.SuccessDicePool.create(3)
      %ExaltedRoller.SuccessDicePool{
        dice: [
          %ExaltedRoller.SuccessDie{value: 10, history: [{10, "Initial"}], frozen: false},
          %ExaltedRoller.SuccessDie{value: 7, history: [{7, "Initial"}], frozen: false},
          %ExaltedRoller.SuccessDie{value: 3, history: [{3, "Initial"}], frozen: false}
        ],
        success: [7, 8, 9, 10],
        double: [10],
        stunt: 0,
        wound: 0,
        auto: 0
      }

      iex> ExaltedRoller.SuccessDicePool.reroll(pool, :not_success, :once)
      %ExaltedRoller.SuccessDicePool{
        dice: [
          %ExaltedRoller.SuccessDie{value: 10, history: [{10, "Initial"}], frozen: false},
          %ExaltedRoller.SuccessDie{value: 7, history: [{7, "Initial"}], frozen: false},
          %ExaltedRoller.SuccessDie{value: 5, history: [{5, "Reroll non successes"}, {3, "Initial"}], frozen: false}
        ],
        success: [7, 8, 9, 10],
        double: [10],
        stunt: 0,
        wound: 0,
        auto: 0
      }

      iex> ExaltedRoller.SuccessDicePool.reroll(pool, [3, 4, 5], :until_none)
      %ExaltedRoller.SuccessDicePool{
        dice: [
          %ExaltedRoller.SuccessDie{value: 10, history: [{10, "Initial"}], frozen: false},
          %ExaltedRoller.SuccessDie{value: 7, history: [{7, "Initial"}], frozen: false},
          %ExaltedRoller.SuccessDie{
            value: 6,
            history: [
              {6, "Reroll until no [3, 4, 5]"}
              {5, "Reroll until no [3, 4, 5]"}
              {3, "Initial"}
            ],
            frozen: false
          }
        ],
        success: [7, 8, 9, 10],
        double: [10],
        stunt: 0,
        wound: 0,
        auto: 0
      }

  """
  @spec reroll(__MODULE__.t(), :not_success | :not_10s | [pos_integer], :once | :until_none) ::
          __MODULE__.t()
  def reroll(%__MODULE__{} = pool, :not_success, :once) do
    reroll(
      pool,
      Enum.filter(1..10, &(not Enum.member?(pool.success, &1))),
      :once,
      "Reroll non successes"
    )
  end

  def reroll(%__MODULE__{} = pool, :not_10s, :once) do
    reroll(pool, [1, 2, 3, 4, 5, 6, 7, 8, 9], :once, "Reroll non 10s")
  end

  def reroll(%__MODULE__{} = pool, values, :once) when is_list(values) do
    reroll(pool, values, :once, "Reroll no #{inspect(values)}")
  end

  def reroll(%__MODULE__{} = pool, values, :until_none) when is_list(values) do
    if Enum.any?(pool.dice, &Enum.member?(values, &1.value)) do
      reroll(pool, values, :once, "Reroll until no #{inspect(values)}")
      |> reroll(values, :until_none)
    else
      pool
    end
  end

  #####################################################################

  @doc false
  @spec reroll(__MODULE__.t(), [pos_integer], :once, String.t()) :: __MODULE__.t()
  defp reroll(%__MODULE__{} = pool, values, :once, reason)
       when is_list(values) and is_binary(reason) do
    %{
      pool
      | dice:
          Enum.map(pool.dice, fn die ->
            if Enum.member?(values, die.value) do
              SuccessDie.roll(die, reason)
            else
              die
            end
          end)
    }
  end
end
