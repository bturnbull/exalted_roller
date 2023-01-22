defmodule ExaultedRollerWeb.RollerLive do
  use ExaultedRollerWeb, :live_view

  require Logger

  alias ExaultedRoller.Tables
  alias ExaultedRoller.Tables.Table

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
        <:actions>
          <.button phx-disable-with="Rolling ..." class="">
            Roll <span aria-hidden="true">→</span>
          </.button>
        </:actions>
      </.simple_form>

      <pre>
        Player: <%= @player.name %>
        Character: <%= @player.character %>
        Table: <%= @table.uid %>
        Players:
        <%= for player <- @players do %>
          <%= player.name %>
        <% end %>
        Rolls:
        <%= for roll <- @table.rolls || [] do %>
          [ <%= for digit <- roll do %><%= digit %>, <% end %> ]
        <% end %>
      </pre>
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
  def handle_event("roll", %{"roll" => %{"dice_count" => dice_count}}, socket) do
    dice_count = String.to_integer(dice_count)

    dice = for i <- 0..dice_count, i > 0, do: :rand.uniform(10)

    case Tables.add_roll(socket.assigns.table, dice) do
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
