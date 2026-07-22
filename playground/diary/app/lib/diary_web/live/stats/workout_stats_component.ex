defmodule DiaryWeb.Stats.WorkoutStatsComponent do
  @moduledoc """
  A reusable component for displaying workout training volume statistics
  aggregated by general and detailed muscle groups.
  """
  use DiaryWeb, :html

  alias Diary.WorkoutMaster

  @doc """
  Renders the workout statistics dashboard.
  """
  attr :stats, :map, required: true
  attr :active_tab, :string, required: true # "weekly", "monthly", or "yearly"
  attr :detail_view, :boolean, required: true
  attr :on_tab_change, :string, default: "set_stats_tab"
  attr :on_toggle_detail, :string, default: "toggle_stats_detail"
  attr :locale, :string, required: true

  def workout_stats(assigns) do
    active_stats = Map.get(assigns.stats, String.to_existing_atom(assigns.active_tab))

    max_general =
      if active_stats && active_stats.general != %{} do
        active_stats.general |> Map.values() |> Enum.max()
      else
        1.0
      end

    # Handle case where all general totals are 0
    max_general = if max_general == 0.0, do: 1.0, else: max_general

    assigns =
      assigns
      |> assign(:active_stats, active_stats)
      |> assign(:max_general, max_general)

    ~H"""
    <div class="bg-white dark:bg-zinc-900 rounded-3xl shadow-xl border border-slate-100 dark:border-zinc-850 overflow-hidden transition-all duration-300">
      <!-- Section Header -->
      <div class="p-8 border-b border-slate-100 dark:border-zinc-800 bg-gradient-to-r from-slate-50 to-white dark:from-zinc-900 dark:to-zinc-900/50 flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
          <h2 class="text-lg font-black text-zinc-800 dark:text-zinc-100 tracking-tight">
            <%= gettext("Training Volume") %>
          </h2>
          <p class="text-xs text-zinc-400 dark:text-zinc-500 font-bold mt-1">Aggregated target muscle work</p>
        </div>

        <!-- Controls: Detail Toggle & Period Tabs -->
        <div class="flex items-center gap-2.5 self-start sm:self-center">
          <!-- Detail View Toggle -->
          <button
            type="button"
            phx-click={@on_toggle_detail}
            class="p-2.5 rounded-xl border border-zinc-200 dark:border-zinc-700 text-zinc-600 dark:text-zinc-400 hover:text-zinc-800 hover:border-zinc-300 hover:bg-zinc-50 dark:hover:bg-zinc-800 transition-all duration-200 cursor-pointer"
            title={if @detail_view, do: gettext("Show General"), else: gettext("Show Details")}
          >
            <%= if @detail_view do %>
              <.icon name="hero-list-bullet" class="size-4" />
            <% else %>
              <.icon name="hero-adjustments-horizontal" class="size-4" />
            <% end %>
          </button>

          <!-- Navigation Tabs -->
          <div class="flex bg-slate-100 dark:bg-zinc-800 p-1 rounded-xl">
            <%= for tab <- ["weekly", "monthly", "yearly"] do %>
              <button
                type="button"
                phx-click={@on_tab_change}
                phx-value-tab={tab}
                class={[
                  "px-3 py-1.5 rounded-lg text-xs font-black transition-all duration-200 cursor-pointer",
                  @active_tab == tab && "bg-white dark:bg-zinc-700 text-zinc-800 dark:text-zinc-100 shadow-sm",
                  @active_tab != tab && "text-slate-400 hover:text-slate-600 dark:hover:text-zinc-300"
                ]}
              >
                <%= case tab do %>
                  <% "weekly" -> %> <%= gettext("Weekly") %>
                  <% "monthly" -> %> <%= gettext("Monthly") %>
                  <% "yearly" -> %> <%= gettext("Yearly") %>
                <% end %>
              </button>
            <% end %>
          </div>
        </div>
      </div>

      <!-- Volume Breakdown Body -->
      <div class="p-8 space-y-6">
        <%= if @active_stats == nil or @active_stats.general == %{} do %>
          <!-- Empty State -->
          <div class="flex flex-col items-center justify-center py-20 text-zinc-300 dark:text-zinc-700">
            <span class="text-4xl mb-2">🏋️</span>
            <p class="text-sm font-medium text-zinc-400 dark:text-zinc-500">{gettext("No data for this period")}</p>
          </div>
        <% else %>
          <%= for {general_group, detailed_parts} <- WorkoutMaster.muscle_groups() do %>
            <%
              general_total = Map.get(@active_stats.general, general_group, 0.0)
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
                    style={"width: #{min(100, (general_total / @max_general) * 100)}%"}
                  ></div>
                </div>

                <!-- Detailed Subparts Breakdown -->
                <%= if @detail_view do %>
                  <div class="pl-4 border-l-2 border-zinc-200 dark:border-zinc-700 space-y-2 mt-2 pt-2 transition-all duration-200">
                    <%= for part <- detailed_parts do %>
                      <%
                        part_total = get_in(@active_stats.detailed, [general_group, part]) || 0.0
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
