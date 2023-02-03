defmodule ExaltedRollerWeb.RollerLive do
  use ExaltedRollerWeb, :live_view

  require Logger

  alias Exalted.SuccessDicePool
  alias ExaltedRoller.Tables
  alias ExaltedRoller.Dice

  import ExaltedRollerWeb.RollerLive.SuccessDicePoolComponent
  import ExaltedRollerWeb.RollerLive.AdjustmentComponent

  @impl true
  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-xl">
      <div class="pt-2">
        <.success_dice_pool pool={@players_roll} character={@player.character} />
      </div>
      <.simple_form
        :let={f}
        id="roll-form"
        for={@changeset}
        phx-change="validate"
        phx-submit="roll"
      >
        <div class="grid grid-cols-4 gap-2 rounded-xl px-2 bg-zinc-100">
          <div class="">
            <.input field={{f, :dice}} type="text" inputmode="numeric" pattern="[0-9]*" required /></div>
          <div class="col-span-2 pt-[5px]"><.adjustment field="dice" type="rel" values={~w[-10 -1 +1 +10]} /></div>
          <div class="pt-1"><.input field={{f, :label}} type="select" prompt="Roll Label" options={["Withering", "Decisive", "Withering Damage", "Decisive Damage", "Reroll", "Cascade", "Social", "Sorcery", "Sidekick", "Join Battle"]} /></div>
        </div>
        <div class="grid grid-cols-2 gap-2 rounded-xl bg-zinc-100">
          <div class="">
            <span class="hidden"><.input field={{f, :stunt}} type="text" inputmode="numeric" pattern="[0-9]*" label="Stunt:" /></span>
            <.adjustment label="Stunt:" field="stunt" type="abs" values={0..3} selected={[@dice_pool.stunt]} />
          </div>
          <div class="">
            <span class="hidden"><.input field={{f, :wound}} type="text" inputmode="numeric" pattern="[-0-9]*" label="Wound:" /></span>
            <.adjustment label="Wound:" field="wound" type="abs" values={0..-4} selected={[@dice_pool.wound]} />
          </div>
        </div>
        <div class="grid rounded-xl bg-zinc-100">
          <span class="hidden"><.input field={{f, :success}} type="select" multiple={true} options={1..10} label="Success:" /></span>
          <.adjustment label="Success:" field="success" type="multi" values={1..10} selected={@dice_pool.success} />
        </div>
        <div class="grid gap-2 rounded-xl bg-zinc-100">
          <span class="hidden"><.input field={{f, :double}} type="select" multiple={true} options={[{"Clear", nil}, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10]} label="Double:" /></span>
          <.adjustment label="Double:" field="double" type="multi" values={1..10} clear={true} selected={@dice_pool.double} />
        </div>
        <div class="grid rounded-xl bg-zinc-100">
          <span class="hidden"><.input field={{f, :reroll_once}} type="select" multiple={true} options={[{"Clear", nil}, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10]} label="Reroll Once:" /></span>
          <.adjustment label="Reroll Once:" field="reroll_once" type="multi" values={1..10} clear={true} selected={@dice_pool.reroll_once} />
        </div>
        <div class="grid rounded-xl bg-zinc-100">
          <span class="hidden"><.input field={{f, :reroll_none}} type="select" multiple={true} options={[{"Clear", nil}, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10]} label="Reroll Until None:" /></span>
          <.adjustment label="Reroll Until None:" field="reroll_none" type="multi" values={1..10} clear={true} selected={@dice_pool.reroll_none} />
        </div>
        <:actions>
          <.button phx-disable-with="Rolling ..." class="w-full">
            Roll <span aria-hidden="true">→</span>
          </.button>
        </:actions>
      </.simple_form>

      <div class="pt-3">
        <ul class="p-3">
          <li><strong>Player:</strong> <%= @player.name %></li>
          <li><strong>Character:</strong> <%= @player.character %></li>
          <li><strong>Players:</strong> [ <%= for player <- @players do %><%= player.character %> <% end %>]</li>
        </ul>
        <div class="">
          <%= for {player, roll} <- @table.rolls || [] do %><.success_dice_pool pool={ roll } character={ player.character } /><% end %>
        </div>
      </div>
    </div>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    ExaltedRollerWeb.Presence.track(self(), table_topic(socket), :player, socket.assigns.player)
    ExaltedRollerWeb.Endpoint.subscribe(table_topic(socket))

    {
      :ok,
      socket
      |> assign_table()
      |> assign_players()
      |> assign_dice_pool()
      |> assign_changeset()
      |> assign_players_roll()
    }
  end

  @impl true
  def handle_event("validate", %{"success_dice_pool" => dice_pool_params}, %{assigns: %{dice_pool: dice_pool}} = socket) do
    changeset =
      dice_pool
      |> Dice.SuccessDicePool.changeset(dice_pool_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :changeset, changeset)}
  end

  @impl true
  def handle_event("validate", _params, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("roll", %{"success_dice_pool" => dice_pool_params}, socket) do
    case Dice.SuccessDicePool.create(dice_pool_params) do
      {:ok, pool} ->
        count = Map.get(pool, :dice)
        once_range = Map.get(pool, :reroll_once)
        until_none_range = Map.get(pool, :reroll_none)
        attrs =
          pool
          |> Map.delete(:dice)
          |> Map.delete(:reroll_once)
          |> Map.delete(:reroll_none)

        pool =
          SuccessDicePool.create(count, Map.to_list(attrs))
          |> SuccessDicePool.reroll(once_range, :once)
          |> SuccessDicePool.reroll(until_none_range, :until_none)

        case Tables.add_roll(socket.assigns.table, socket.assigns.player, pool) do
          %Tables.Table{} = table ->
            ExaltedRollerWeb.Endpoint.broadcast_from(self(), table_topic(socket), "roll_update", nil)
            {
              :noreply,
              socket
              |> assign(:table, table)
              |> assign(:players_roll, pool)
            }

          _ ->
            {:noreply, socket}
        end

      {:error, changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  @impl true
  def handle_event("adjustment", %{"field" => field, "type" => type, "value" => value}, %{assigns: %{dice_pool: dice_pool}} = socket) do
    with {value, _} <- Integer.parse(value),
         true <- Enum.any?(["dice", "stunt", "wound", "success", "double", "reroll_once", "reroll_none"], &(&1 == field)),
         true <- Enum.any?(["rel", "abs", "multi"], &(&1 == type)),
         field <- String.to_atom(field),
         type <- String.to_atom(type)
    do
      value = apply_adjustment(type, field, value, dice_pool)

      changeset =
        dice_pool
        |> Dice.SuccessDicePool.changeset(Map.put(%{}, field, value))
        |> Map.put(:action, :validate)

      if changeset.valid? do
        {
          :noreply,
          socket
          |> assign(:dice_pool, Map.put(dice_pool, field, value))
          |> assign(:changeset, changeset)
        }
      else
        {:noreply, socket}
      end
    else
      _ ->
        {:noreply, socket}
    end
  end

  def handle_event("clear", %{"field" => field, "type" => "multi"}, %{assigns: %{dice_pool: dice_pool}} = socket) do
    with true <- Enum.any?(["dice", "stunt", "wound", "success", "double", "reroll_once", "reroll_none"], &(&1 == field)),
         field <- String.to_atom(field)
    do
      changeset =
        dice_pool
        |> Dice.SuccessDicePool.changeset(Map.put(%{}, field, [nil]))
        |> Map.put(:action, :validate)

      dice_pool = Map.put(dice_pool, field, [nil])

      {
        :noreply,
        socket
        |> assign(:dice_pool, dice_pool)
        |> assign(:changeset, changeset)
      }
    else
      _ ->
        {:noreply, socket}
    end
  end

  defp apply_adjustment(:abs, _field, value, _dice_pool) do
    value
  end

  defp apply_adjustment(:rel, field, value, dice_pool) do
    Map.get(dice_pool, field) + value
  end

  defp apply_adjustment(:multi, _field, 0, _dice_pool) do
    []
  end

  defp apply_adjustment(:multi, field, value, dice_pool) do
    current = Map.get(dice_pool, field, [])

    if Enum.any?(current, &(&1 == value)) do
      List.delete(current, value)
    else
      List.insert_at(current, -1, value)
      |> Enum.sort()
      |> Enum.uniq()
    end
  end

  @impl true
  def handle_info(%{event: "presence_diff", payload: _payload}, socket) do
    {:noreply, assign(socket, :players, table_players(socket))}
  end

  @impl true
  def handle_info(%{event: "roll_update"}, socket) do
    case Tables.fetch(socket.assigns.table) do
      %Tables.Table{} = table ->
        {:noreply, assign(socket, :table, table)}

      _ ->
        {:noreply, socket}
    end
  end

  defp assign_table(%{} = socket) do
    socket
    |> assign(:table, Tables.fetch(socket.assigns.table))
  end

  defp assign_players(%{} = socket) do
    socket
    |> assign(:players, table_players(socket))
  end

  defp assign_dice_pool(%{} = socket) do
    socket
    |> assign(:dice_pool, %Dice.SuccessDicePool{})   # Dice.create_success_dice_pool
  end

  defp assign_changeset(%{assigns: %{dice_pool: dice_pool}} = socket) do
    socket
    |> assign(:changeset, Dice.SuccessDicePool.changeset(dice_pool, %{}))   # Dice.create_success_dice_pool
  end

  defp assign_changeset(%{} = socket) do
    socket
    |> assign(:changeset, Dice.SuccessDicePool.changeset(%Dice.SuccessDicePool{}, %{}))
  end

  defp assign_players_roll(%{} = socket) do
    socket
    |> assign(:players_roll, Tables.get_latest_roll(socket.assigns.table, socket.assigns.player))
  end

  defp table_topic(socket) do
    "table:#{socket.assigns.table.uid}"
  end

  # Returns all players joined to this table sorted by character name with this
  # session's player first.
  defp table_players(socket) do
    table_topic(socket)
    |> ExaltedRollerWeb.Presence.list()
    |> Enum.map(fn {_, data} -> data[:metas] end)
    |> List.first()
    |> Enum.sort_by(& &1.character, :asc)
    |> Enum.sort_by(&(&1.character == socket.assigns.player.character), :desc)
  end
end
