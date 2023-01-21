defmodule ExaultedRollerWeb.PlayerJoinLive do
  use ExaultedRollerWeb, :live_view

  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-sm">
      <.header class="text-center">
        Join a table!
        <:subtitle>
          Leave "Table Code" blank to create a new table.
        </:subtitle>
      </.header>

      <.simple_form
        :let={f}
        id="login_form"
        for={:table}
        action={~p"/join"}
        as={:table}
        phx-update="ignore"
      >
        <.input field={{f, :character_name}} type="text" label="Character Name" required />
        <.input field={{f, :player_name}} type="text" label="Player Name" required />
        <.input field={{f, :table_uid}} type="text" label="Table Code" />

        <:actions>
          <.button phx-disable-with="Joining ..." class="w-full">
            Join <span aria-hidden="true">→</span>
          </.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    {:ok, socket}
  end
end
