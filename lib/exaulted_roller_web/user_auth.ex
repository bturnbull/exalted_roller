defmodule ExaultedRollerWeb.UserAuth do
  use ExaultedRollerWeb, :verified_routes

  import Plug.Conn
  import Phoenix.Controller

  alias ExaultedRoller.Players
  alias ExaultedRoller.Players.Player
  alias ExaultedRoller.Tables
  alias ExaultedRoller.Tables.Table

  def join_table(conn, %{"player_name" => player_name, "character_name" => character_name, "table_uid" => ""} = _params) do
    case Tables.create() do
      %Table{} = table ->
        join_table(conn, %{"player_name" => player_name, "character_name" => character_name, "table_uid" => table.uid})

      _ ->
        redirect(conn, to: join_path(conn))
    end
  end

  def join_table(conn, %{"player_name" => player_name, "character_name" => character_name, "table_uid" => table_uid} = _params) do
    with %Player{} = player <- Players.create(name: player_name, character: character_name),
         %Table{} = table <- Tables.fetch(table_uid)
    do
      conn
      |> put_session(:player, player)
      |> put_session(:table, table)
      |> redirect(to: signed_in_path(conn))
    else
      _ ->
        conn
        |> put_flash(:error, "Table not found.")
        |> redirect(to: join_path(conn))
    end
  end

  def join_table(conn, _) do
    redirect(conn, to: join_path(conn))
  end

  def leave_table(conn, _params) do
    conn
    |> delete_session(:table)
    |> redirect(to: join_path(conn))
  end

  @doc """
  Authenticates the player by looking into the session
  """
  def fetch_current_player(conn, _opts) do
    assign(conn, :player, get_session(conn, :player))
  end

  @doc """
  Authenticates the table by looking into the session
  """
  def fetch_current_table(conn, _opts) do
    case Tables.fetch(get_session(conn, :table)) do
      %Table{} = table ->
        assign(conn, :table, table)

      _ ->
        delete_session(conn, :table)
    end
  end

  @doc """
  Handles mounting and joining the player in LiveViews.

  ## `on_mount` arguments

    * `:mount_player_and_table` - Assigns player and table
      to socket assigns

    * `:ensure_joined` - Redirects to login page if player not
      joined to table

    * `:redirect_if_player_is_joined` - Redirects to the table
      session if the player is joined.

  ## Examples

  Use the `on_mount` lifecycle macro in LiveViews to mount or authenticate
  the current_user:

      defmodule ExaultedRollerWeb.PageLive do
        use ExaultedRollerWeb, :live_view

        on_mount {ExaultedRollerWeb.UserAuth, :mount_player_and_table}
        ...
      end

  Or use the `live_session` of your router to invoke the on_mount callback:

      live_session :authenticated, on_mount: [{ExaultedRollerWeb.UserAuth, :ensure_joined}] do
        live "/profile", ProfileLive, :index
      end
  """
  def on_mount(:mount_player_and_table, _params, session, socket) do
    {:cont, mount_player_and_table(session, socket)}
  end

  def on_mount(:ensure_joined, _params, session, socket) do
    socket = mount_player_and_table(session, socket)

    if is_nil(socket.assigns.table) or is_nil(socket.assigns.player) do
      {:halt, Phoenix.LiveView.redirect(socket, to: join_path(socket))}
    else
      {:cont, socket}
    end
  end

  def on_mount(:redirect_if_player_is_joined, _params, session, socket) do
    socket = mount_player_and_table(session, socket)

    if is_nil(socket.assigns.table) or is_nil(socket.assigns.player) do
      {:cont, socket}
    else
      {:halt, Phoenix.LiveView.redirect(socket, to: signed_in_path(socket))}
    end
  end

  defp mount_player_and_table(session, socket) do
    case session do
      %{"player" => player, "table" => table} ->
        socket
        |> Phoenix.Component.assign_new(:table, fn -> table end)
        |> Phoenix.Component.assign_new(:player, fn -> player end)

      %{} ->
        socket
        |> Phoenix.Component.assign_new(:table, fn -> nil end)
        |> Phoenix.Component.assign_new(:player, fn -> nil end)
    end
  end

  @doc """
  Used for routes that require the player to not be joined to a table.
  """
  def redirect_if_player_is_joined(conn, _opts) do
    case conn.assigns[:table] do
      %{} ->
        conn
        |> redirect(to: signed_in_path(conn))
        |> halt()

      _ ->
        conn
    end
  end

  @doc """
  Used for routes that require the player to be joined to a table.
  """
  def require_joined_player(conn, _opts) do
    case {conn.assigns[:player], conn.assigns[:table]} do
      {%{}, %{}} ->
        conn

      _ ->
        conn
        |> redirect(to: join_path(conn))
        |> halt()
    end
  end

  def join_path(_conn), do: ~p"/join"
  def signed_in_path(_conn), do: ~p"/"
end
