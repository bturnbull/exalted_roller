defmodule ExaultedRollerWeb.RollerLive.AdjustmentComponent do
  use Phoenix.Component

  attr :field, :string, required: true
  attr :type, :string, required: true
  attr :values, :list, required: true
  attr :clear, :boolean, default: false

  def adjustment(assigns) do
    ~H"""
    <div class="">
      <%= if @clear do %><a href="#" phx-click="clear" phx-value-field={@field} phx-value-type={@type}>None</a>
        <% end %>
      <%= for value <- @values do %><a href="#" phx-click="adjustment" phx-value-field={@field} phx-value-type={@type} phx-value-value={value}><%= value %></a>
        <% end %>
    </div>
    """
  end
end
