defmodule ExaultedRollerWeb.RollerLive.SuccessDicePoolComponent do
  use Phoenix.Component

  alias ExaultedRoller.SuccessDicePool

  def success_dice_pool(assigns) do
    ~H"""
    <div>
      <h2><%= SuccessDicePool.success_count(@pool) %> Successes (<%= @character %>)</h2>
      <ul>
        <li><strong>Roll:</strong> <%= dice_list_as_string(Enum.map(@pool.dice, &(&1.value))) %></li>
        <li><strong>Success:</strong> <%= dice_list_as_string(@pool.success) %></li>
        <li><strong>Double:</strong> <%= dice_list_as_string(@pool.double) %></li>
        <li><strong>Stunt:</strong> <%= @pool.stunt %></li>
        <li><strong>Wound:</strong> <%= @pool.wound %></li>
      </ul>
    </div>
    """
  end

  defp dice_list_as_string(dice) do
    dice_list_string =
      dice
      |> Enum.map(&(Integer.to_string(&1)))
      |> Enum.join(", ")

    "[ #{dice_list_string} ]"
  end
end
