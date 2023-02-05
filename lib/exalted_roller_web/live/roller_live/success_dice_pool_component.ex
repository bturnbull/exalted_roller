defmodule ExaltedRollerWeb.RollerLive.SuccessDicePoolComponent do
  use Phoenix.Component

  alias Exalted.SuccessDie
  alias Exalted.SuccessDicePool

  def success_dice_pool(%{pool: nil} = assigns) do
    ~H"""
    <div class="p-3 bg-zinc-200 odd:bg-zinc-100">
      <div class="text-center text-xl">
        <strong><%= @character %></strong> has not rolled
      </div>
      <div class="text-center text-zinc-500">
        0 Dice / [ ] / [ ] / A:0 / S:0 / W:0 / <strike>R1: [ ] / Rn: [ ]</strike>
      </div>
    </div>
    """
  end

  def success_dice_pool(assigns) do
    ~H"""
    <div class="p-3 bg-zinc-200 odd:bg-zinc-100">
      <div class="text-center text-xl">
        <strong><%= @character %></strong> rolls
        <%= if @pool.label do %> <strong><%= @pool.label %></strong> for <% end %>
        <span class={success_string_class(@pool)}><strong><%= success_string(@pool) %></strong></span>
      </div>
      <div><.success_dice_pool_roll pool={@pool} /></div>
      <div class="text-center text-zinc-500">
        <%= dice_count_string(@pool) %> / <%= integer_list_as_string(@pool.success) %> / <%= integer_list_as_string(
          @pool.double
        ) %> / A:<%= SuccessDicePool.automatic_success_count(@pool) %> / S:<%= @pool.stunt %> / W:<%= @pool.wound %> / <strike>R1: [ ] / Rn: [ ]</strike>
      </div>
    </div>
    """
  end

  def success_dice_pool_roll(assigns) do
    assigns = assign_success_dice_pool_table_extants(assigns)

    ~H"""
    <%= for i <- 0..@tables do %><.success_dice_pool_table pool={@pool} range={(i*@columns)..((i+1)*@columns-1)} />
    <% end %>
    """
  end

  def success_dice_pool_table(assigns) do
    assigns = assign_success_dice_pool_rows(assigns)

    ~H"""
    <div class="pt-2">
      <table class="table-fixed text-zinc-100 border-4 border-transparent m-auto">
        <thead class="">
          <tr class="">
            <%= for die <- Enum.slice(@pool.dice, @range) do %><th class={success_die_class(:final, @pool, die)}><.success_die pool={@pool} die={die} /></th><% end %>
          </tr>
        </thead>
        <tbody>
          <%= for row <- 0..@rows do %><tr class="bg-zinc-300">
            <%= for die <- Enum.slice(@pool.dice, @range) do %><td class={success_die_class(:reroll, @pool, Enum.at(die.history, row+1))}><.success_die pool={@pool} die={Enum.at(die.history, row+1)} /></td><% end %>
          </tr><% end %>
        </tbody>
      </table>
    </div>
    """
  end

  def success_die(%{die: {value, reason}} = assigns) do
    assign(assigns, :die, %SuccessDie{value: value, history: [{value, reason}]})
    |> success_die()
  end

  def success_die(%{die: nil} = assigns) do
    ~H"""
    <span class="">-</span>
    """
  end

  def success_die(assigns) do
    ~H"""
    <span class=""><%= @die.value %></span>
    """
  end

  defp success_die_class(type, %SuccessDicePool{} = pool, {value, reason} = _die) do
    success_die_class(type, pool, %SuccessDie{value: value, history: [{value, reason}]})
  end

  defp success_die_class(_type, %SuccessDicePool{} = _pool, nil) do
    "w-8 text-center text-transparent"
  end

  defp success_die_class(:final = type, %SuccessDicePool{} = pool, %SuccessDie{} = die) do
    "w-8 text-center pb-[3px]"
    |> success_die_success_class(type, pool, die)
    |> success_die_double_class(type, pool, die)
  end

  defp success_die_class(:reroll = type, %SuccessDicePool{} = pool, %SuccessDie{} = die) do
    "w-8 text-center pb-[3px]"
    |> success_die_success_class(type, pool, die)
    |> success_die_double_class(type, pool, die)
  end

  defp success_die_success_class(class, :final, %SuccessDicePool{} = pool, %SuccessDie{} = die) do
    if SuccessDicePool.die_success?(pool, die),
      do: "font-bold bg-amber-600 #{class}",
      else: "bg-zinc-700 #{class}"
  end

  defp success_die_success_class(class, :reroll, %SuccessDicePool{} = pool, %SuccessDie{} = die) do
    if SuccessDicePool.die_success?(pool, die),
      do: "font-bold bg-amber-700 #{class}",
      else: "bg-zinc-600 #{class}"
  end

  defp success_die_double_class(class, :final, %SuccessDicePool{} = pool, %SuccessDie{} = die) do
    if SuccessDicePool.die_double?(pool, die),
      do: "underline underline-offset-2 #{class}",
      else: class
  end

  defp success_die_double_class(class, :reroll, %SuccessDicePool{} = pool, %SuccessDie{} = die) do
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

  defp assign_success_dice_pool_rows(%{pool: pool, range: range} = assigns) do
    rows =
      pool.dice
      |> Enum.slice(range)
      |> Enum.map(&(length(&1.history)))
      |> Enum.max(&>=/2, fn -> 0 end)

    assign(assigns, :rows, max(rows - 2, 0))
  end

  defp assign_success_dice_pool_table_extants(%{pool: pool} = assigns) do
    tables = div(length(pool.dice), 20) + 1
    columns = div(length(pool.dice), tables) + 1

    assigns
    |> assign(:tables, tables)
    |> assign(:columns, columns)
  end
end
