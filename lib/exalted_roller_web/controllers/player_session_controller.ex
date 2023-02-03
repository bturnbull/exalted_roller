defmodule ExaltedRollerWeb.PlayerSessionController do
  use ExaltedRollerWeb, :controller

  alias ExaltedRollerWeb.UserAuth

  def create(conn, %{"table" => table_params} = _param) do
    UserAuth.join_table(conn, table_params)
  end

  def delete(conn, params) do
    UserAuth.leave_table(conn, params)
  end
end
