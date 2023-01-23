defmodule ExaultedRollerWeb.RollerLive.SuccessDicePoolComponent do
  use Phoenix.Component

  alias ExaultedRoller.SuccessDie
  alias ExaultedRoller.SuccessDicePool

  def success_dice_pool(assigns) do
    ~H"""
    <div class="p-3 bg-slate-200 odd:bg-slate-100">
      <div><strong><%= @character %>:</strong> <%= success_string(@pool) %> <%= automatic_string(@pool) %></div>
      <div><strong>Roll:</strong> <.success_dice_pool_roll pool={ @pool } /></div>
      <div><%= integer_list_as_string(@pool.success) %> / <%= integer_list_as_string(@pool.double) %> / S:<%= @pool.stunt %> / W:<%= @pool.wound %></div>
    </div>
    """
  end

  def success_dice_pool_roll(assigns) do
    ~H"""
    <span>[ <%= for die <- @pool.dice do %><.success_die pool={ @pool } die={ die } /> <% end %>]</span>
    """
  end

  def success_die(assigns) do
    ~H"""
    <span class={ success_die_class(@pool, @die) }><%= @die.value %></span>
    """
  end

  defp success_die_class(%SuccessDicePool{} = pool, %SuccessDie{} = die) do
    ""
    |> success_die_success_class(pool, die)
    |> success_die_double_class(pool, die)
  end

  defp success_die_success_class(class, %SuccessDicePool{} = pool, %SuccessDie{} = die) do
    if SuccessDicePool.die_success?(pool, die), do: "font-bold text-green-600 #{class}", else: class
  end

  defp success_die_double_class(class, %SuccessDicePool{} = pool, %SuccessDie{} = die) do
    if SuccessDicePool.die_double?(pool, die), do: "underline underline-offset-2 #{class}", else: class
  end

  defp integer_list_as_string(ints) when is_list(ints) do
    rep =
      ints
      |> Enum.map(&(Integer.to_string(&1)))
      |> Enum.join(" ")

    "[ #{rep} ]"
  end

  defp success_string(pool) do
    case SuccessDicePool.success_count(pool) do
      1 ->
        "1 Success"

      count ->
        "#{count} Successes"
    end
  end

  defp automatic_string(pool) do
    "(#{SuccessDicePool.automatic_success_count(pool)} Automatic)"
  end
end
