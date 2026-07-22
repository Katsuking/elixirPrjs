defmodule DiaryWeb.StatsLive do
  @moduledoc """
  LiveView for displaying and managing workout training volume statistics.
  """
  use DiaryWeb, :live_view
  use Gettext, backend: DiaryWeb.Gettext

  import DiaryWeb.DatePickerComponent
  import DiaryWeb.Stats.WorkoutStatsComponent

  alias Diary.Notebook

  @impl true
  def mount(_params, session, socket) do
    locale = session["locale"] || "en"
    Gettext.put_locale(DiaryWeb.Gettext, locale)

    date = Date.utc_today()
    stats = Notebook.get_workout_stats(date)

    if connected?(socket) do
      # Subscribe to workout updates for the selected date
      Phoenix.PubSub.subscribe(Diary.PubSub, "diary:#{date}")
    end

    {:ok,
     socket
     |> assign(date: date)
     |> assign(:locale, locale)
     |> assign(stats: stats)
     |> assign(active_tab: "weekly")
     |> assign(detail_view: false)}
  end

  @impl true
  def handle_params(_params, _uri, socket) do
    locale = Gettext.get_locale(DiaryWeb.Gettext)
    {:noreply, assign(socket, :locale, locale)}
  end

  @impl true
  # Handle changing date from date picker input
  def handle_event("change_date", %{"date" => date_str}, socket) do
    date = Date.from_iso8601!(date_str)
    {:noreply, select_date_helper(socket, date)}
  end

  # Handle adjusting date via back/forward buttons
  def handle_event("adjust_date", %{"days" => days_str}, socket) do
    days = String.to_integer(days_str)
    date = Date.add(socket.assigns.date, days)
    {:noreply, select_date_helper(socket, date)}
  end

  # Handle jumping to today's date
  def handle_event("go_to_today", _params, socket) do
    today = Date.utc_today()
    {:noreply, select_date_helper(socket, today)}
  end

  @impl true
  # Handle switching active stats tab (weekly / monthly / yearly)
  def handle_event("set_stats_tab", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, active_tab: tab)}
  end

  @impl true
  # Handle toggling detailed muscle breakdown view
  def handle_event("toggle_stats_detail", _params, socket) do
    {:noreply, assign(socket, detail_view: !socket.assigns.detail_view)}
  end

  @impl true
  # Handle PubSub messages for workout log updates
  def handle_info({:workout_log_updated, _date}, socket) do
    stats = Notebook.get_workout_stats(socket.assigns.date)
    {:noreply, assign(socket, stats: stats)}
  end

  # Helper to set the active date and reload stats
  defp select_date_helper(socket, date) do
    stats = Notebook.get_workout_stats(date)

    if connected?(socket) do
      Phoenix.PubSub.unsubscribe(Diary.PubSub, "diary:#{socket.assigns.date}")
      Phoenix.PubSub.subscribe(Diary.PubSub, "diary:#{date}")
    end

    socket
    |> assign(date: date)
    |> assign(stats: stats)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} active_tab="stats">
      <div class="max-w-2xl mx-auto space-y-6">
        <!-- Date Navigator Card -->
        <div class="bg-white dark:bg-zinc-900 rounded-3xl shadow-xl border border-slate-100 dark:border-zinc-850 p-6">
          <.date_navigator date={@date} on_change="change_date">
            <:prev_button_content>
              <span class="text-xs">Prev</span>
            </:prev_button_content>

            <:today_button_content>
              <span>today</span>
            </:today_button_content>

            <:next_button_content>
              <span class="text-xs">Next</span>
            </:next_button_content>
          </.date_navigator>
        </div>

        <!-- Workout Volume Statistics -->
        <.workout_stats
          stats={@stats}
          active_tab={@active_tab}
          detail_view={@detail_view}
          on_tab_change="set_stats_tab"
          on_toggle_detail="toggle_stats_detail"
          locale={@locale}
        />
      </div>
    </Layouts.app>
    """
  end
end
