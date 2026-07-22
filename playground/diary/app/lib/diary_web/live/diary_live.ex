defmodule DiaryWeb.DiaryLive do
  @moduledoc """
  LiveView for managing and displaying bullet diary items.
  """
  use DiaryWeb, :live_view
  use Gettext, backend: DiaryWeb.Gettext

  import DiaryWeb.Components.Diary.CalendarComponent
  import DiaryWeb.DatePickerComponent # Import the custom date picker component
  import DiaryWeb.Components.Diary.WorkoutStatsComponent

  alias Diary.Notebook
  alias Diary.DiaryItem

  @impl true
  def mount(_params, session, socket) do
    # Retrieve locale saved by the router plug (fallback to "en")
    locale = session["locale"] || "en"
    Gettext.put_locale(DiaryWeb.Gettext, locale)

    # Get today's date
    date = Date.utc_today()
    diary_items = Notebook.list_diary_items(date)
    changeset = Notebook.change_diary_item(%DiaryItem{date: date})

    # Initialize calendar states
    current_calendar_month = Date.beginning_of_month(date)
    leading_days_count = Date.day_of_week(current_calendar_month, :sunday) - 1
    calendar_start_date = Date.add(current_calendar_month, -leading_days_count)
    calendar_end_date = Date.add(calendar_start_date, 41)
    calendar_days = Enum.map(0..41, &Date.add(calendar_start_date, &1))

    # Fetch calendar data from DB
    calendar_entry_dates = Notebook.list_calendar_data(calendar_start_date, calendar_end_date)
    stats = Notebook.get_workout_stats(date)

    {:ok,
     socket
     |> subscribe_to_date(date)
     |> assign(date: date)
     |> assign(content_length: 0)
     |> assign(form: to_form(changeset))
     |> assign(:locale, locale)
     |> assign(current_calendar_month: current_calendar_month)
     |> assign(calendar_days: calendar_days)
     |> assign(calendar_start_date: calendar_start_date)
     |> assign(calendar_end_date: calendar_end_date)
     |> assign(calendar_entry_dates: calendar_entry_dates)
     |> assign(stats: stats)
     |> assign(active_tab: "weekly")
     |> assign(detail_view: false)
     |> stream(:diary_items, diary_items)}
  end

  @impl true
  def handle_params(_params, _uri, socket) do
    # Locale already set in mount; just keep socket assign in sync
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
  # Handle switching active stats tab (weekly / monthly / yearly) on the homepage
  def handle_event("set_stats_tab", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, active_tab: tab)}
  end

  @impl true
  # Handle toggling detailed muscle breakdown view on the homepage
  def handle_event("toggle_stats_detail", _params, socket) do
    {:noreply, assign(socket, detail_view: !socket.assigns.detail_view)}
  end

  # Handle selecting a specific date from the calendar grid
  def handle_event("select_date", %{"date" => date_str}, socket) do
    date = Date.from_iso8601!(date_str)
    {:noreply, push_navigate(socket, to: ~p"/workout/#{Date.to_iso8601(date)}")}
  end

  # Handle navigating to the previous month in the calendar
  def handle_event("prev_month", _params, socket) do
    new_month = shift_month(socket.assigns.current_calendar_month, -1)
    {:noreply, update_calendar_month(socket, new_month)}
  end

  # Handle navigating to the next month in the calendar
  def handle_event("next_month", _params, socket) do
    new_month = shift_month(socket.assigns.current_calendar_month, 1)
    {:noreply, update_calendar_month(socket, new_month)}
  end



  # Handle inline form validation to track characters count and errors
  def handle_event("validate", %{"diary_item" => %{"content" => content}}, socket) do
    changeset =
      %DiaryItem{date: socket.assigns.date}
      |> Notebook.change_diary_item(%{"content" => content})
      |> Map.put(:action, :validate)

    {:noreply,
     socket
     |> assign(form: to_form(changeset))
     |> assign(content_length: String.length(content))}
  end

  # Handle saving new diary item
  def handle_event("save", %{"diary_item" => %{"content" => content}}, socket) do
    case Notebook.create_diary_item(%{"date" => socket.assigns.date, "content" => content}) do
      {:ok, diary_item} ->

        # Clear input on success
        changeset = Notebook.change_diary_item(%DiaryItem{date: socket.assigns.date})

        {:noreply,
         socket
         |> stream_insert(:diary_items, diary_item)
         |> assign(form: to_form(changeset))
         |> assign(content_length: 0)
         |> put_flash(:info, gettext("Successfully added!"))}

      {:error, changeset} ->
        # Display validation errors
        {:noreply,
         socket
         |> assign(form: to_form(changeset))}
    end
  end

  # Handle deletion of a diary item
  def handle_event("delete", %{"id" => id}, socket) do
    diary_item = Notebook.get_diary_item!(id)

    case Notebook.delete_diary_item(diary_item) do
      {:ok, deleted_item} ->
        {:noreply,
         socket
         |> stream_delete(:diary_items, deleted_item)
         |> put_flash(:info, gettext("Deleted!"))}

      {:error, _changeset} ->
        {:noreply,
         socket
         |> put_flash(:error, gettext("Failed to delete item."))}
    end
  end

  defp subscribe_to_date(socket, new_date) do
    if connected?(socket) do
      if old_date = socket.assigns[:date] do
        Phoenix.PubSub.unsubscribe(Diary.PubSub, "diary:#{old_date}")
      end
      Phoenix.PubSub.subscribe(Diary.PubSub, "diary:#{new_date}")
    end
    socket
  end

  @impl true
  # Handle PubSub messages for item creation
  def handle_info({:diary_item_created, diary_item}, socket) do
    socket =
      if diary_item.date == socket.assigns.date do
        stream_insert(socket, :diary_items, diary_item)
      else
        socket
      end

    # Refresh calendar data if the item falls in the currently displayed range
    socket =
      if Date.compare(diary_item.date, socket.assigns.calendar_start_date) != :lt and
         Date.compare(diary_item.date, socket.assigns.calendar_end_date) != :gt do
        assign_calendar_data(socket, socket.assigns.calendar_start_date, socket.assigns.calendar_end_date)
      else
        socket
      end

    {:noreply, socket}
  end

  @impl true
  # Handle PubSub messages for item deletion
  def handle_info({:diary_item_deleted, diary_item}, socket) do
    socket = stream_delete(socket, :diary_items, diary_item)

    # Refresh calendar data if the item falls in the currently displayed range
    socket =
      if Date.compare(diary_item.date, socket.assigns.calendar_start_date) != :lt and
         Date.compare(diary_item.date, socket.assigns.calendar_end_date) != :gt do
        assign_calendar_data(socket, socket.assigns.calendar_start_date, socket.assigns.calendar_end_date)
      else
        socket
      end

    {:noreply, socket}
  end

  @impl true
  # Handle PubSub messages for workout log updates
  def handle_info({:workout_log_updated, _date}, socket) do
    stats = Notebook.get_workout_stats(socket.assigns.date)
    {:noreply, assign(socket, stats: stats)}
  end



  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <div class="bg-slate-50 min-h-screen py-12 px-4 sm:px-6 lg:px-8">
        <div class="max-w-6xl mx-auto grid grid-cols-1 lg:grid-cols-2 gap-8">
          
          <!-- Left side: Calendar + Diary Items -->
          <div class="bg-white rounded-3xl shadow-xl border border-slate-100 overflow-hidden transition-all duration-300">

            <!-- Card Header with App Title and Navigation -->
            <div class="p-8 border-b border-slate-100 bg-gradient-to-r from-slate-50 to-white space-y-4">

              <%!-- Override the button contents using named slots --%>
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

              <div class="flex justify-center">
                <.link
                  navigate={~p"/workout/#{Date.to_iso8601(@date)}"}
                  class="w-full flex items-center justify-center gap-2 py-3 bg-zinc-800 hover:bg-zinc-900 text-white font-extrabold rounded-2xl shadow-md transition-all duration-200 cursor-pointer text-sm"
                >
                  💪 {gettext("Log Workouts")}
                </.link>
              </div>

            </div>

            <!-- Calendar Section -->
            <.calendar
              current_calendar_month={@current_calendar_month}
              calendar_days={@calendar_days}
              calendar_entry_dates={@calendar_entry_dates}
              date={@date}
              locale={@locale}
            />

            <!-- Diary Bullet Points List -->
            <div class="p-8">
              <h2 class="text-xs font-bold text-slate-400 uppercase tracking-widest mb-4">
                Today's Entries
              </h2>

              <div id="diary-items" phx-update="stream" class="space-y-3.5 min-h-[160px]">
                <!-- Empty State -->
                <div id="diary-empty-state" class="hidden only:flex flex-col items-center justify-center py-10 text-slate-300">
                  <span class="text-5xl mb-3">🍃</span>
                  <p class="text-sm font-medium text-slate-400">No entries for this day. Add one below!</p>
                </div>

                <!-- Stream Item Row -->
                <div
                  :for={{id, item} <- @streams.diary_items}
                  id={id}
                  class="group flex items-center justify-between p-4 bg-slate-50/60 hover:bg-zinc-50/50 border border-slate-100 hover:border-zinc-300 rounded-2xl transition-all duration-200"
                >
                  <div class="flex items-start gap-3.5 pr-4">
                    <span class="flex-shrink-0 text-lg select-none text-zinc-500 group-hover:scale-110 transition-transform duration-200">•</span>
                    <p class="text-slate-700 font-medium break-all leading-relaxed">{item.content}</p>
                  </div>

                  <!-- Actions (Delete button) -->
                  <div class="flex items-center gap-1 opacity-0 group-hover:opacity-100 transition-opacity duration-200">
                    <button
                      type="button"
                      phx-click="delete"
                      phx-value-id={item.id}
                      id={"delete-item-#{item.id}"}
                      class="p-1.5 text-slate-400 hover:text-rose-500 rounded-lg hover:bg-rose-50 transition-all duration-200 cursor-pointer"
                      title="Delete item"
                    >
                      <.icon name="hero-trash" class="size-4" />
                    </button>
                  </div>
                </div>
              </div>
            </div>



            <!-- Add Entry Form Area -->
            <div class="p-8 bg-slate-50/80 border-t border-slate-100">
              <h2 class="text-xs font-bold text-slate-400 uppercase tracking-widest mb-4">
                Add New Entry
              </h2>

              <.form for={@form} id="new-diary-item-form" phx-change="validate" phx-submit="save" class="space-y-4">
                <div class="relative">
                  <!-- Custom styles on core components to override daisyUI defaults -->
                  <.input
                    field={@form[:content]}
                    type="text"
                    placeholder="What did you do today?"
                    autocomplete="off"
                    id="diary-item-content-input"
                    class="w-full pl-4 pr-20 py-3.5 text-slate-700 bg-white border border-slate-200 rounded-2xl focus:ring-2 focus:ring-zinc-800/10 focus:border-zinc-800 outline-none transition-all duration-200 placeholder:text-slate-400 shadow-sm"
                    error_class="border-rose-500 focus:ring-rose-500/20 focus:border-rose-500"
                  />

                  <!-- Length character counter overlay -->
                  <div class={[
                    "absolute right-3.5 top-3.5 text-xs font-bold px-2 py-1 rounded-lg select-none pointer-events-none transition-colors duration-200",
                    @content_length > 50 && "text-rose-600 bg-rose-50",
                    @content_length in 41..50 && "text-amber-600 bg-amber-50",
                    @content_length <= 40 && "text-slate-400 bg-slate-100"
                  ]}>
                    {@content_length}/50
                  </div>
                </div>

                <div class="flex items-center justify-end">
                  <button
                    type="submit"
                    id="submit-item-btn"
                    disabled={@content_length == 0 or @content_length > 50}
                    class="flex items-center gap-2 px-6 py-3 bg-zinc-800 hover:bg-zinc-900 disabled:bg-slate-200 text-white disabled:text-slate-400 font-bold rounded-2xl shadow-lg shadow-zinc-850/10 hover:shadow-zinc-850/20 disabled:shadow-none transition-all duration-200 transform active:scale-[0.98] disabled:transform-none cursor-pointer disabled:cursor-not-allowed"
                  >
                    <.icon name="hero-plus" class="size-4" /> Add Bullet
                  </button>
                </div>
              </.form>
            </div>
          </div>

          <!-- Right side: Workout Volume Statistics -->
          <.workout_stats
            stats={@stats}
            active_tab={@active_tab}
            detail_view={@detail_view}
            on_tab_change="set_stats_tab"
            on_toggle_detail="toggle_stats_detail"
            locale={@locale}
          />

        </div>
      </div>
    </Layouts.app>
    """
  end

  # Helper functions for the calendar logic

  # Helper to set the active date, load its data, and dynamically adjust the calendar month if needed.
  defp select_date_helper(socket, date) do
    diary_items = Notebook.list_diary_items(date)
    changeset = Notebook.change_diary_item(%DiaryItem{date: date})
    stats = Notebook.get_workout_stats(date)

    socket =
      socket
      |> subscribe_to_date(date)
      |> assign(date: date)
      |> assign(content_length: 0)
      |> assign(form: to_form(changeset))
      |> assign(stats: stats)
      |> stream(:diary_items, diary_items, reset: true)

    # Shift calendar month if the selected date belongs to a different month
    target_month = Date.beginning_of_month(date)

    if Date.compare(target_month, socket.assigns.current_calendar_month) != :eq do
      update_calendar_month(socket, target_month)
    else
      socket
    end
  end

  # Helper to calculate and assign all calendar grid days and fetch the corresponding data.
  defp update_calendar_month(socket, new_month) do
    leading_days_count = Date.day_of_week(new_month, :sunday) - 1
    calendar_start_date = Date.add(new_month, -leading_days_count)
    calendar_end_date = Date.add(calendar_start_date, 41)
    calendar_days = Enum.map(0..41, &Date.add(calendar_start_date, &1))

    socket
    |> assign(current_calendar_month: new_month)
    |> assign(calendar_days: calendar_days)
    |> assign(calendar_start_date: calendar_start_date)
    |> assign(calendar_end_date: calendar_end_date)
    |> assign_calendar_data(calendar_start_date, calendar_end_date)
  end

  # Helper to assign queried calendar data (entry dates) to the socket.
  defp assign_calendar_data(socket, start_date, end_date) do
    entry_dates = Notebook.list_calendar_data(start_date, end_date)

    socket
    |> assign(:calendar_entry_dates, entry_dates)
  end

  # Helper to shift a month forward or backward by month offset, returning the 1st of that month.
  defp shift_month(date, offset) do
    year = date.year
    month = date.month

    {new_year, new_month} =
      case month + offset do
        0 -> {year - 1, 12}
        13 -> {year + 1, 1}
        m -> {year, m}
      end

    Date.new!(new_year, new_month, 1)
  end

end
