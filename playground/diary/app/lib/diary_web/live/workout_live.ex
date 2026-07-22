defmodule DiaryWeb.WorkoutLive do
  @moduledoc """
  LiveView for managing and displaying workout logs and muscle volume stats.
  """
  use DiaryWeb, :live_view
  use Gettext, backend: DiaryWeb.Gettext

  alias Diary.Notebook
  alias Diary.WorkoutMaster

  @impl true
  def mount(%{"date" => date_str}, session, socket) do
    # Retrieve locale saved by the session (fallback to "en")
    locale = session["locale"] || "en"
    Gettext.put_locale(DiaryWeb.Gettext, locale)

    # Parse target date, falling back to today if invalid
    date =
      case Date.from_iso8601(date_str) do
        {:ok, parsed_date} -> parsed_date
        _ -> Date.utc_today()
      end

    # Subscribe to PubSub for real-time synchronization on this date
    if connected?(socket) do
      Phoenix.PubSub.subscribe(Diary.PubSub, "diary:#{date}")
    end

    # Fetch initial state data
    exercises = WorkoutMaster.exercises()
    logs = Notebook.list_workout_logs(date)
    stats = Notebook.get_workout_stats(date)

    {:ok,
     socket
     |> assign(date: date)
     |> assign(exercises: exercises)
     |> assign(logs: logs)
     |> assign(stats: stats)
     |> assign(active_tab: "weekly") # Default active stats tab
     |> assign(detail_view: false) # Default to general muscle groups view
     |> assign(locale: locale)}
  end

  @impl true
  # Handle live weight input saving
  def handle_event("save_weight", %{"weights" => weights_params}, socket) do
    date = socket.assigns.date

    # Iterate over all exercises and upsert weights
    Enum.each(weights_params, fn {exercise, weight_str} ->
      weight =
        case Float.parse(weight_str) do
          {w, _} -> w
          :error -> 0.0
        end

      Notebook.save_workout_log(date, exercise, weight)
    end)

    # Reload data after updates
    logs = Notebook.list_workout_logs(date)
    stats = Notebook.get_workout_stats(date)

    {:noreply,
     socket
     |> assign(logs: logs)
     |> assign(stats: stats)
     |> put_flash(:info, gettext("Weights updated!"))}
  end

  @impl true
  # Handle switching active stats tab (weekly / monthly / yearly)
  def handle_event("set_tab", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, active_tab: tab)}
  end

  @impl true
  # Handle toggling detailed muscle breakdown view
  def handle_event("toggle_detail", _params, socket) do
    {:noreply, assign(socket, detail_view: !socket.assigns.detail_view)}
  end

  @impl true
  # Handle PubSub notifications to update logs in real-time
  def handle_info({:workout_log_updated, date}, socket) do
    if Date.compare(date, socket.assigns.date) == :eq do
      logs = Notebook.list_workout_logs(date)
      stats = Notebook.get_workout_stats(date)
      {:noreply, assign(socket, logs: logs, stats: stats)}
    else
      {:noreply, socket}
    end
  end

  # Catch-all handle_info to prevent crashes on unrelated events
  def handle_info(_other, socket) do
    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <div class="bg-slate-50 min-h-screen py-12 px-4 sm:px-6 lg:px-8">
      <div class="max-w-4xl mx-auto space-y-8">
        
        <!-- Header Section -->
        <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4 bg-white p-6 rounded-3xl shadow-sm border border-slate-100">
          <div class="space-y-1">
            <h1 class="text-2xl font-extrabold text-slate-800 tracking-tight flex items-center gap-2">
              <span class="text-3xl">💪</span> {gettext("Training Logs")}
            </h1>
            <p class="text-sm font-semibold text-slate-500">
              {format_date(@date, @locale)}
            </p>
          </div>
          <div class="flex items-center gap-2">
            <.link
              navigate={~p"/"}
              class="flex items-center gap-2 px-5 py-2.5 bg-slate-100 hover:bg-slate-200 text-slate-700 font-bold rounded-2xl shadow-sm transition-all duration-200 cursor-pointer text-sm"
            >
              <.icon name="hero-arrow-left" class="size-4" /> {gettext("Back to Diary")}
            </.link>
          </div>
        </div>

        <div class="grid grid-cols-1 lg:grid-cols-2 gap-8">
          
          <!-- Exercise Input List Card -->
          <div class="bg-white rounded-3xl shadow-md border border-slate-100 p-8 space-y-6">
            <h2 class="text-lg font-bold text-slate-800 flex items-center gap-2">
              <span class="text-indigo-500 font-extrabold">●</span> {gettext("Input Weights")}
            </h2>

            <form id="workout-weights-form" phx-change="save_weight" class="space-y-3.5 max-h-[500px] overflow-y-auto pr-2">
              <%= for exercise <- @exercises do %>
                <% log = Map.get(@logs, exercise) %>
                <div class="flex items-center justify-between p-4 bg-slate-50 rounded-2xl border border-slate-100 hover:border-indigo-100 hover:bg-indigo-50/10 transition-all duration-200">
                  <span class="font-bold text-slate-700 text-sm">{exercise}</span>
                  <div class="flex items-center gap-2">
                    <input
                      type="number"
                      name={"weights[#{exercise}]"}
                      value={log && log.weight}
                      step="0.5"
                      min="0"
                      placeholder="0"
                      phx-debounce="600"
                      class="w-24 text-right font-extrabold text-slate-700 bg-white border border-slate-200 rounded-xl py-2 px-3 focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 outline-none transition-all duration-200 shadow-sm"
                    />
                    <span class="text-xs font-extrabold text-slate-400">kg</span>
                  </div>
                </div>
              <% end %>
            </form>
          </div>

          <!-- Muscle Volume Statistics Card -->
          <div class="bg-white rounded-3xl shadow-md border border-slate-100 p-8 space-y-6">
            <div class="flex items-center justify-between">
              <h2 class="text-lg font-bold text-slate-800 flex items-center gap-2">
                <span class="text-indigo-500 font-extrabold">●</span> {gettext("Training Volume")}
              </h2>
              <button
                type="button"
                phx-click="toggle_detail"
                class="px-4 py-1.5 bg-indigo-50 hover:bg-indigo-100 text-indigo-700 text-xs font-bold rounded-xl transition-all duration-200 cursor-pointer"
              >
                <%= if @detail_view, do: gettext("Show General"), else: gettext("Show Details") %>
              </button>
            </div>

            <!-- Stats Period Tabs -->
            <div class="flex p-1 bg-slate-100 rounded-2xl">
              <%= for {tab_key, label} <- [
                {"weekly", gettext("Weekly")},
                {"monthly", gettext("Monthly")},
                {"yearly", gettext("Yearly")}
              ] do %>
                <button
                  type="button"
                  phx-click="set_tab"
                  phx-value-tab={tab_key}
                  class={[
                    "flex-1 text-center py-2 text-sm font-bold rounded-xl transition-all duration-200 cursor-pointer",
                    @active_tab == tab_key && "bg-white text-slate-800 shadow-sm",
                    @active_tab != tab_key && "text-slate-500 hover:text-slate-700"
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
                <div class="flex flex-col items-center justify-center py-20 text-slate-300">
                  <span class="text-4xl mb-2">🏋️</span>
                  <p class="text-sm font-medium text-slate-400">{gettext("No data for this period")}</p>
                </div>
              <% else %>
                <%= for {general_group, detailed_parts} <- WorkoutMaster.muscle_groups() do %>
                  <%
                    general_total = Map.get(active_stats.general, general_group, 0.0)
                  %>
                  <%= if general_total > 0.0 do %>
                    <div class="p-4 bg-slate-50/50 rounded-2xl border border-slate-100 space-y-2">
                      <div class="flex items-center justify-between">
                        <span class="font-extrabold text-slate-700 text-sm">{general_group}</span>
                        <span class="font-black text-indigo-600 text-sm">{Float.round(general_total, 1)} kg</span>
                      </div>

                      <!-- Progress bar for the general group -->
                      <div class="w-full bg-slate-200/60 h-2.5 rounded-full overflow-hidden">
                        <div
                          class="bg-indigo-600 h-full rounded-full transition-all duration-500"
                          style={"width: #{min(100, (general_total / max_general) * 100)}%"}
                        ></div>
                      </div>

                      <!-- Detailed Subparts Breakdown -->
                      <%= if @detail_view do %>
                        <div class="pl-4 border-l-2 border-indigo-100 space-y-2 mt-2 pt-2">
                          <%= for part <- detailed_parts do %>
                            <%
                              part_total = get_in(active_stats.detailed, [general_group, part]) || 0.0
                            %>
                            <%= if part_total > 0.0 do %>
                              <div class="space-y-1">
                                <div class="flex items-center justify-between text-xs font-bold text-slate-500">
                                  <span>{part}</span>
                                  <span>{Float.round(part_total, 1)} kg</span>
                                </div>
                                <!-- Sub-progress bar -->
                                <div class="w-full bg-slate-200/40 h-1.5 rounded-full overflow-hidden">
                                  <div
                                    class="bg-indigo-400 h-full rounded-full transition-all duration-500"
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

        </div>

      </div>
    </div>
    </Layouts.app>
    """
  end

  # Helper to format the display date depending on the locale
  defp format_date(date, locale) do
    case locale do
      "ja" ->
        "#{date.year}年 #{date.month}月#{date.day}日"

      _ ->
        month_name =
          case date.month do
            1 -> "January"
            2 -> "February"
            3 -> "March"
            4 -> "April"
            5 -> "May"
            6 -> "June"
            7 -> "July"
            8 -> "August"
            9 -> "September"
            10 -> "October"
            11 -> "November"
            12 -> "December"
          end

        "#{month_name} #{date.day}, #{date.year}"
    end
  end
end
