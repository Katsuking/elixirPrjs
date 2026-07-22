defmodule DiaryWeb.Components.Diary.WorkoutStatsComponent do
  @moduledoc """
  Functional component to display workout volume statistics with progress bars.
  """
  use Phoenix.Component
  use Gettext, backend: DiaryWeb.Gettext

  alias Diary.WorkoutMaster

  attr :stats, :map, required: true
  attr :active_tab, :string, default: "weekly"
  attr :detail_view, :boolean, default: false
  attr :on_tab_change, :string, default: "set_stats_tab"
  attr :on_toggle_detail, :string, default: "toggle_stats_detail"
  attr :locale, :string, default: "en"

  @doc """
  Renders the workout training volume statistics interface.
  """
  def workout_stats(assigns) do
    ~H"""
    <div class="bg-white dark:bg-zinc-900 rounded-3xl shadow-xl border border-slate-100 dark:border-zinc-850 p-8 space-y-6">
      <div class="flex items-center justify-between">
        <h2 class="text-lg font-black text-zinc-800 dark:text-zinc-100 flex items-center gap-2">
          <span class="text-zinc-600 dark:text-zinc-400 font-extrabold text-xl">📊</span> {gettext("Training Volume")}
        </h2>
        <button
          type="button"
          phx-click={@on_toggle_detail}
          class="px-4 py-1.5 bg-zinc-100 hover:bg-zinc-200 text-zinc-800 dark:bg-zinc-800 dark:hover:bg-zinc-700 dark:text-zinc-200 text-xs font-bold rounded-xl transition-all duration-200 cursor-pointer"
        >
          <%= if @detail_view, do: gettext("Show General"), else: gettext("Show Details") %>
        </button>
      </div>

      <!-- Stats Period Tabs -->
      <div class="flex p-1 bg-zinc-100 dark:bg-zinc-800 rounded-2xl">
        <%= for {tab_key, label} <- [
          {"weekly", gettext("Weekly")},
          {"monthly", gettext("Monthly")},
          {"yearly", gettext("Yearly")}
        ] do %>
          <button
            type="button"
            phx-click={@on_tab_change}
            phx-value-tab={tab_key}
            class={[
              "flex-1 text-center py-2.5 text-xs font-bold rounded-xl transition-all duration-200 cursor-pointer",
              @active_tab == tab_key && "bg-white text-zinc-800 dark:bg-zinc-700 dark:text-zinc-100 shadow-sm",
              @active_tab != tab_key && "text-zinc-500 hover:text-zinc-700 dark:text-zinc-400 dark:hover:text-zinc-200"
            ]}
          >
            {label}
          </button>
        <% end %>
      </div>

      <!-- Muscle Volume Chart Rows -->
      <div class="space-y-4 max-h-[420px] overflow-y-auto pr-2">
        <%
          active_stats = Map.get(@stats, String.to_existing_atom(@active_tab))
          max_general = Enum.max(Map.values(active_stats.general) ++ [1.0])
        %>
        <%= if Enum.empty?(active_stats.general) do %>
          <div class="flex flex-col items-center justify-center py-20 text-zinc-300 dark:text-zinc-700">
            <span class="text-4xl mb-2">🏋️</span>
            <p class="text-sm font-medium text-zinc-400 dark:text-zinc-500">{gettext("No data for this period")}</p>
          </div>
        <% else %>
          <%= for {general_group, detailed_parts} <- WorkoutMaster.muscle_groups() do %>
            <%
              general_total = Map.get(active_stats.general, general_group, 0.0)
            %>
            <%= if general_total > 0.0 do %>
               <div class="p-4 bg-zinc-50/50 dark:bg-zinc-800/40 rounded-2xl border border-zinc-100/80 dark:border-zinc-800 space-y-2 hover:border-zinc-250 dark:hover:border-zinc-700 transition-all duration-200">
                <div class="flex items-center justify-between">
                  <span class="font-extrabold text-zinc-700 dark:text-zinc-300 text-sm">{Gettext.gettext(DiaryWeb.Gettext, general_group)}</span>
                  <span class="font-black text-zinc-800 dark:text-zinc-100 text-sm">{format_volume(general_total)} kg</span>
                </div>

                <!-- Progress bar for the general group -->
                <div class="w-full bg-zinc-200/60 dark:bg-zinc-800 h-2.5 rounded-full overflow-hidden">
                  <div
                    class="bg-zinc-800 dark:bg-zinc-300 h-full rounded-full transition-all duration-500"
                    style={"width: #{min(100, (general_total / max_general) * 100)}%"}
                  ></div>
                </div>

                <!-- Detailed Subparts Breakdown -->
                <%= if @detail_view do %>
                  <div class="pl-4 border-l-2 border-zinc-200 dark:border-zinc-700 space-y-2 mt-2 pt-2 transition-all duration-200">
                    <%= for part <- detailed_parts do %>
                      <%
                        part_total = get_in(active_stats.detailed, [general_group, part]) || 0.0
                      %>
                      <%= if part_total > 0.0 do %>
                        <div class="space-y-1">
                          <div class="flex items-center justify-between text-xs font-bold text-zinc-500 dark:text-zinc-400">
                            <span>{Gettext.gettext(DiaryWeb.Gettext, part)}</span>
                            <span>{format_volume(part_total)} kg</span>
                          </div>
                          <!-- Sub-progress bar -->
                          <div class="w-full bg-zinc-200/40 dark:bg-zinc-800/50 h-1.5 rounded-full overflow-hidden">
                            <div
                              class="bg-zinc-500 dark:bg-zinc-400 h-full rounded-full transition-all duration-500"
                              style={"width: #{min(100, (part_total / general_total) * 100)}%"}
                            ></div>
                          </div>
                        </div>
                      <% end %>
                    <% end %>
                  </div>
                <% end %>
              </div>
            <% end %>
          <% end %>
        <% end %>
      </div>
    </div>
    """
  end

  # Helper to format floats to decimal notation without scientific symbols
  defp format_volume(volume) when is_float(volume) do
    :erlang.float_to_binary(volume, [:compact, decimals: 1])
  end
  defp format_volume(volume) when is_integer(volume) do
    to_string(volume)
  end
  defp format_volume(_), do: "0.0"
end
