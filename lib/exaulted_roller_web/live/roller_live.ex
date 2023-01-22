defmodule ExaultedRollerWeb.RollerLive do
  use ExaultedRollerWeb, :live_view

  require Logger

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
      <pre>
        Player: <%= @player.name %>
        Character: <%= @player.character %>
        Table: <%= @table.uid %>
        Players:
        <%= for player <- @players do %>
          <%= player.name %>
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
      |> assign(:players, table_players(socket))
    }
  end

  @impl true
  def handle_info(%{event: "presence_diff", payload: _payload}, socket) do
    {:noreply, assign(socket, :players, table_players(socket))}
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
