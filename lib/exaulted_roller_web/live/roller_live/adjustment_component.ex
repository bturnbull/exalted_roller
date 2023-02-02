defmodule ExaultedRollerWeb.RollerLive.AdjustmentComponent do
  use Phoenix.Component

  attr :label, :string, default: nil
  attr :field, :string, required: true
  attr :type, :string, required: true
  attr :values, :list, required: true
  attr :clear, :boolean, default: false
  attr :selected, :list, default: []

  def adjustment(assigns) do
    ~H"""
    <div class={grid_div_container_class(assigns)}>
    <%= if @label do %><span class="flex items-center pl-2 pb-1 gap-4 text-sm leading-6 font-bold text-zinc-700"><%= @label %></span><% end %>
      <%= if @clear do %><a href="#" phx-click="clear" phx-value-field={@field} phx-value-type={@type}><div class={grid_div_button_class(assigns, nil, @selected)}>None</div></a>
        <% end %>
        <%= for value <- @values do %><a href="#" phx-click="adjustment" phx-value-field={@field} phx-value-type={@type} phx-value-value={value}><div class={grid_div_button_class(assigns, value, @selected)}><%= value %></div></a>
        <% end %>
    </div>
    """
  end

  defp grid_div_container_class(assigns) do
    "w-full columns-#{count(assigns)} space-x-2 rounded-xl bg-gray-200 p-2"
  end

  defp grid_div_button_class(_assigns, nil, []) do
    "inline-block w-16 cursor-pointer select-none rounded-xl p-1 text-center font-bold border-2 border-blue-500 border-solid bg-blue-500 text-white hover:bg-blue-400 hover:text-white"
  end

  defp grid_div_button_class(_assigns, nil, [nil]) do
    "inline-block w-16 cursor-pointer select-none rounded-xl p-1 text-center font-bold border-2 border-blue-500 border-solid bg-blue-500 text-white hover:bg-blue-400 hover:text-white"
  end

  defp grid_div_button_class(_assigns, nil, selected) do
    "inline-block w-16 cursor-pointer select-none rounded-xl p-1 text-center font-bold border-2 border-blue-500 border-solid bg-blue-50 text-blue-500 hover:bg-blue-400 hover:text-white"
  end

  defp grid_div_button_class(assigns, value, selected) do
    common_styles = "inline-block #{width(assigns)} cursor-pointer select-none rounded-xl p-1 text-center font-bold"
    if Enum.any?(selected, &(&1 == value)) do
      "border-2 border-blue-500 border-solid bg-blue-500 text-white hover:bg-blue-400 hover:text-white #{common_styles}"
    else
      "border-2 border-blue-500 border-solid bg-blue-50 text-blue-500 hover:bg-blue-400 hover:text-white #{common_styles}"
    end
  end

  defp width(assigns) do
    case count(assigns) do
      c when c in 0..5 ->
        "w-[2.8rem]"

      _ ->
        "w-[2.2rem]"
    end
  end

  defp count(assigns) do
    length(Enum.to_list(assigns.values)) + if assigns.clear, do: 1, else: 0
  end
end
