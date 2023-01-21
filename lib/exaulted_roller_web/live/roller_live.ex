defmodule ExaultedRollerWeb.RollerLive do
  use ExaultedRollerWeb, :live_view

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
      </pre>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    {:ok, socket}
  end
end
