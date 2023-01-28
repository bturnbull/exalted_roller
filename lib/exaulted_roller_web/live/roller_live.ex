defmodule ExaultedRollerWeb.RollerLive do
  use ExaultedRollerWeb, :live_view

  require Logger

  alias Exaulted.SuccessDicePool
  alias ExaultedRoller.Tables
  alias ExaultedRoller.Dice

  import ExaultedRollerWeb.RollerLive.SuccessDicePoolComponent

  @impl true
  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-sm">
      <.header class="text-center">
        Roller!
        <:subtitle>
          <.link href={~p"/leave"} method="delete">Leave Table</.link>
        </:subtitle>
      </.header>
      <.simple_form
        :let={f}
        id="roll-form"
        for={@changeset}
        phx-change="validate"
        phx-submit="roll"
      >
        <.input field={{f, :dice}} type="text" inputmode="numeric" pattern="[0-9]*" label="Dice Count:" required />
        <.input field={{f, :stunt}} type="text" inputmode="numeric" pattern="[0-9]*" label="Stunt:" />
        <.input field={{f, :wound}} type="text" inputmode="numeric" pattern="[-0-9]*" label="Wound:" />
        <.input field={{f, :success}} type="select" multiple={true} options={1..10} label="Success:" />
        <.input field={{f, :double}} type="select" multiple={true} options={[{"Clear", nil}, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10]} label="Double:" />
        <.input field={{f, :reroll_once}} type="select" multiple={true} options={[{"Clear", nil}, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10]} label="Reroll Once:" />
        <.input field={{f, :reroll_none}} type="select" multiple={true} options={[{"Clear", nil}, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10]} label="Reroll Until None:" />
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
          <li><strong>Table:</strong> <%= @table.uid %></li>
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
    ExaultedRollerWeb.Presence.track(self(), table_topic(socket), :player, socket.assigns.player)
    ExaultedRollerWeb.Endpoint.subscribe(table_topic(socket))

    {
      :ok,
      socket
      |> assign_table()
      |> assign_players()
      |> assign_dice_pool()
      |> assign_changeset()
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
  def handle_event("validate", params, socket) do
    Logger.debug("params = #{inspect params}")
    Logger.debug("socket.assigns = #{inspect socket.assigns}")

    {:noreply, socket}
  end

  @impl true
  def handle_event("roll", %{"success_dice_pool" => dice_pool_params}, socket) do
    Logger.debug("dice_pool_params = #{inspect dice_pool_params}")

    case Dice.SuccessDicePool.create(dice_pool_params) do
      {:ok, pool} ->
        Logger.debug("pool = #{inspect pool}")

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

        Logger.debug("pool = #{inspect pool}")

        case Tables.add_roll(socket.assigns.table, socket.assigns.player, pool) do
          %Tables.Table{} = table ->
            ExaultedRollerWeb.Endpoint.broadcast_from(self(), table_topic(socket), "roll_update", nil)
            {:noreply, assign(socket, :table, table)}

          _ ->
            {:noreply, socket}
        end

      {:error, changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  @impl true
  def handle_info(%{event: "presence_diff", payload: _payload}, socket) do
    {:noreply, assign(socket, :players, table_players(socket))}
  end

  @impl true
  def handle_info(%{event: "roll_update"}, socket) do
    case Tables.join(uid: socket.assigns.table.uid) do
      %Tables.Table{} = table ->
        {:noreply, assign(socket, :table, table)}

      _ ->
        {:noreply, socket}
    end
  end

  defp assign_table(%{} = socket) do
    socket
    |> assign(:table, Tables.join(uid: socket.assigns.table.uid))
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

  defp table_topic(socket) do
    "table:#{socket.assigns.table.uid}"
  end

  # Returns all players joined to this table sorted by character name with this
  # session's player first.
  defp table_players(socket) do
    table_topic(socket)
    |> ExaultedRollerWeb.Presence.list()
    |> Enum.map(fn {_, data} -> data[:metas] end)
    |> List.first()
    |> Enum.sort_by(& &1.character, :asc)
    |> Enum.sort_by(&(&1.character == socket.assigns.player.character), :desc)
  end
end
