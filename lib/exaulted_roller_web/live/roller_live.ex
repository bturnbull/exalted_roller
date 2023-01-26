defmodule ExaultedRollerWeb.RollerLive do
  use ExaultedRollerWeb, :live_view

  require Logger

  alias Exaulted.SuccessDicePool
  alias ExaultedRoller.Tables
  alias ExaultedRoller.Tables.Table

  import ExaultedRollerWeb.RollerLive.SuccessDicePoolComponent

  @impl true
  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-sm">
      <.header class="text-center">
        Roller!
        <:subtitle>
          <.link href={~p"/leave"} method="delete">Leave</.link>
        </:subtitle>
      </.header>
      <.simple_form
        :let={f}
        id="roll_form"
        for={:roll}
        as={:roll}
        phx-submit="roll"
      >
        <.input field={{f, :dice_count}} type="text" label="Dice Count:" required />
        <.input field={{f, :stunt}} type="text" value="0" label="Stunt:" required />
        <.input field={{f, :wound}} type="text" value="0" label="Wound:" required />
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
      |> assign(:table, Tables.join(uid: socket.assigns.table.uid))
      |> assign(:players, table_players(socket))
    }
  end

  @impl true
  def handle_event("roll", %{"roll" => %{"dice_count" => dice_count, "wound" => wound, "stunt" => stunt}}, socket) do
    pool =
      SuccessDicePool.create(
        String.to_integer(dice_count),
        stunt: String.to_integer(stunt),
        wound: String.to_integer(wound)
      )

    case Tables.add_roll(socket.assigns.table, socket.assigns.player, pool) do
      %Table{} = table ->
        ExaultedRollerWeb.Endpoint.broadcast_from(self(), table_topic(socket), "roll_update", nil)
        {:noreply, assign(socket, :table, table)}

      _ ->
        {:noreply, socket}
    end
  end

  @impl true
  def handle_info(%{event: "presence_diff", payload: _payload}, socket) do
    {:noreply, assign(socket, :players, table_players(socket))}
  end

  @impl true
  def handle_info(%{event: "roll_update"}, socket) do
    case Tables.join(uid: socket.assigns.table.uid) do
      %Table{} = table ->
        {:noreply, assign(socket, :table, table)}

      _ ->
        {:noreply, socket}
    end
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
