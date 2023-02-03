defmodule ExaltedRollerWeb.RollerLive.SuccessDicePoolComponent do
  use Phoenix.Component

  alias Exalted.SuccessDie
  alias Exalted.SuccessDicePool

  def success_dice_pool(%{pool: nil} = assigns) do
    ~H"""
    <div class="p-3 bg-zinc-100 odd:bg-zinc-200">
      <div>
        <strong><%= @character %>:</strong>
        <span class={success_string_class(nil)}>&mdash;</span>
      </div>
      <div><strong>Roll:</strong> &mdash;</div>
      <div>
        &mdash; / &mdash; / &mdash; / &mdash; / &mdash;
      </div>
    </div>
    """
  end

  def success_dice_pool(assigns) do
    ~H"""
    <div class="p-3 bg-zinc-200 odd:bg-zinc-100">
      <div>
        <strong><%= @character %></strong> rolls
        <%= if @pool.label do %> <strong><%= @pool.label %></strong> for <% end %>
        <span class={success_string_class(@pool)}><strong><%= success_string(@pool) %></strong></span>
      </div>
      <div><strong>Roll:</strong> <.success_dice_pool_roll pool={@pool} /></div>
      <div>
        <%= dice_count_string(@pool) %> / <%= integer_list_as_string(@pool.success) %> / <%= integer_list_as_string(
          @pool.double
        ) %> / A:<%= SuccessDicePool.automatic_success_count(@pool) %> / S:<%= @pool.stunt %> / W:<%= @pool.wound %>
      </div>
    </div>
    """
  end

  def success_dice_pool_roll(assigns) do
    ~H"""
    <span>
      [
      <%= for die <- @pool.dice do %>
        <.success_die pool={@pool} die={die} />
      <% end %>]
    </span>
    """
  end

  def success_die(assigns) do
    ~H"""
    <span class={success_die_class(@pool, @die)}><%= @die.value %></span>
    """
  end

  defp success_die_class(%SuccessDicePool{} = pool, %SuccessDie{} = die) do
    ""
    |> success_die_success_class(pool, die)
    |> success_die_double_class(pool, die)
  end

  defp success_die_success_class(class, %SuccessDicePool{} = pool, %SuccessDie{} = die) do
    if SuccessDicePool.die_success?(pool, die),
      do: "font-bold text-green-600 #{class}",
      else: class
  end

  defp success_die_double_class(class, %SuccessDicePool{} = pool, %SuccessDie{} = die) do
    if SuccessDicePool.die_double?(pool, die),
      do: "underline underline-offset-2 #{class}",
      else: class
  end

  defp integer_list_as_string(ints) when is_list(ints) do
    rep =
      ints
      |> Enum.map(&Integer.to_string(&1))
      |> Enum.join(" ")

    "[ #{rep} ]"
  end

  defp success_string(pool) do
    case {SuccessDicePool.success_count(pool), SuccessDicePool.botch?(pool)} do
      {0, true} ->
        "Botch!"

      {1, _} ->
        "1 Success"

      {count, _} ->
        "#{count} Successes"
    end
  end

  defp success_string_class(nil) do
    ""
  end

  defp success_string_class(pool) do
    if SuccessDicePool.botch?(pool),
      do: "text-red-600 font-bold",
      else: ""
  end

  defp dice_count_string(pool) do
    case length(pool.dice) do
      1 ->
        "1 Die"

      count ->
        "#{count} Dice"
    end
  end
end
