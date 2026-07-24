defmodule DiaryWeb.DiaryLive do
  @moduledoc """
  LiveView for managing and displaying bullet diary items and the monthly calendar.
  """
  use DiaryWeb, :live_view
  use Gettext, backend: DiaryWeb.Gettext

  import DiaryWeb.Diary.CalendarComponent
  import DiaryWeb.DatePickerComponent

  alias Diary.Notebook
  alias Diary.DiaryItem

  @impl true
  def mount(_params, session, socket) do
    locale = session["locale"] || "en"
    Gettext.put_locale(DiaryWeb.Gettext, locale)

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
    total_volume = Notebook.get_workout_volume_for_date(date)

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
     |> assign(total_volume: total_volume)
     |> stream(:diary_items, diary_items)}
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

  # Handle inline form validation to track characters count
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
  # Handle PubSub messages for workout log updates to refresh total daily volume
  def handle_info({:workout_log_updated, date}, socket) do
    socket =
      if date == socket.assigns.date do
        assign(socket, total_volume: Notebook.get_workout_volume_for_date(date))
      else
        socket
      end

    # Refresh calendar data if the update falls in the currently displayed range
    socket =
      if Date.compare(date, socket.assigns.calendar_start_date) != :lt and
         Date.compare(date, socket.assigns.calendar_end_date) != :gt do
        assign_calendar_data(socket, socket.assigns.calendar_start_date, socket.assigns.calendar_end_date)
      else
        socket
      end

    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} active_tab="diary">
      <div class="max-w-2xl mx-auto bg-white dark:bg-zinc-900 rounded-3xl shadow-xl border border-slate-100 dark:border-zinc-850 overflow-hidden transition-all duration-300">

        <!-- Card Header with App Title and Navigation -->
        <div class="p-8 border-b border-slate-100 dark:border-zinc-800 bg-gradient-to-r from-slate-50 to-white dark:from-zinc-900 dark:to-zinc-900/50 space-y-4">
          <.date_navigator date={@date} on_change="change_date">
            <:prev_button_content>
              <!-- Show chevron icon on mobile, and add 'Prev' text on larger screens -->
              <div class="flex items-center gap-1">
                <.icon name="hero-chevron-left" class="size-4" />
                <span class="hidden sm:inline text-xs">{gettext("Prev")}</span>
              </div>
            </:prev_button_content>

            <:today_button_content>
              <!-- Responsive text size for today button -->
              <span class="text-xs sm:text-sm">{gettext("today")}</span>
            </:today_button_content>

            <:next_button_content>
              <!-- Show chevron icon on mobile, and add 'Next' text on larger screens -->
              <div class="flex items-center gap-1">
                <span class="hidden sm:inline text-xs">{gettext("Next")}</span>
                <.icon name="hero-chevron-right" class="size-4" />
              </div>
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

          <div :if={@total_volume > 0.0} class="flex items-center justify-between px-5 py-3.5 bg-slate-50/60 dark:bg-zinc-800/40 border border-slate-100 dark:border-zinc-800/60 rounded-2xl">
            <div class="flex items-center gap-2">
              <span class="text-base select-none">🏋️‍♂️</span>
              <span class="text-[10px] font-black text-slate-400 dark:text-zinc-500 uppercase tracking-wider">{gettext("Today's Volume")}</span>
            </div>
            <span class="text-sm font-black text-zinc-800 dark:text-zinc-100">{format_volume(@total_volume)} kg</span>
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
          <h2 class="text-xs font-bold text-slate-400 dark:text-zinc-500 uppercase tracking-widest mb-4">
            {gettext("Today's Entries")}
          </h2>

          <div id="diary-items" phx-update="stream" class="space-y-3.5 min-h-[160px]">
            <!-- Empty State -->
            <div id="diary-empty-state" class="hidden only:flex flex-col items-center justify-center py-10 text-slate-300 dark:text-zinc-700">
              <img src={~p"/images/nodata.svg"} class="w-32 h-auto mb-3" alt="No data" />
              <p class="text-sm font-medium text-slate-400 dark:text-zinc-500">{gettext("No entries for this day. Add one below!")}</p>
            </div>

            <!-- Stream Item Row -->
            <div
              :for={{id, item} <- @streams.diary_items}
              id={id}
              class="group flex items-center justify-between p-4 bg-slate-50/60 hover:bg-zinc-50/50 dark:bg-zinc-800/40 dark:hover:bg-zinc-800/80 border border-slate-100 dark:border-zinc-850 hover:border-zinc-300 dark:hover:border-zinc-700 rounded-2xl transition-all duration-200"
            >
              <div class="flex items-start gap-3.5 pr-4">
                <span class="flex-shrink-0 text-lg select-none text-zinc-500 group-hover:scale-110 transition-transform duration-200">•</span>
                <p class="text-slate-700 dark:text-zinc-300 font-medium break-all leading-relaxed">{item.content}</p>
              </div>

              <!-- Actions (Delete button) -->
              <div class="flex items-center gap-1 opacity-0 group-hover:opacity-100 transition-opacity duration-200">
                <button
                  type="button"
                  phx-click="delete"
                  phx-value-id={item.id}
                  id={"delete-item-#{item.id}"}
                  class="p-1.5 text-slate-400 hover:text-rose-500 rounded-lg hover:bg-rose-50 dark:hover:bg-rose-950/30 transition-all duration-200 cursor-pointer"
                  title={gettext("Delete item")}
                >
                  <.icon name="hero-trash" class="size-4" />
                </button>
              </div>
            </div>
          </div>
        </div>

        <!-- Add Entry Form Area -->
        <div class="p-8 bg-slate-50/80 dark:bg-zinc-800/20 border-t border-slate-100 dark:border-zinc-800">
          <h2 class="text-xs font-bold text-slate-400 dark:text-zinc-500 uppercase tracking-widest mb-4">
            {gettext("Add New Entry")}
          </h2>

          <.form for={@form} id="new-diary-item-form" phx-change="validate" phx-submit="save" class="space-y-4">
            <div class="relative">
              <.input
                field={@form[:content]}
                type="text"
                placeholder={gettext("What did you do today?")}
                autocomplete="off"
                id="diary-item-content-input"
                class="w-full pl-4 pr-20 py-3.5 text-slate-700 dark:text-zinc-250 bg-white dark:bg-zinc-900 border border-slate-200 dark:border-zinc-800 rounded-2xl focus:ring-2 focus:ring-zinc-800/10 focus:border-zinc-800 outline-none transition-all duration-200 placeholder:text-slate-400 dark:placeholder:text-zinc-600 shadow-sm"
                error_class="border-rose-500 focus:ring-rose-500/20 focus:border-rose-500"
              />

              <!-- Length character counter overlay -->
              <div class={[
                "absolute right-3.5 top-3.5 text-xs font-bold px-2 py-1 rounded-lg select-none pointer-events-none transition-colors duration-200",
                @content_length > 50 && "text-rose-600 bg-rose-50 dark:bg-rose-950/20",
                @content_length in 41..50 && "text-amber-600 bg-amber-50 dark:bg-amber-950/20",
                @content_length <= 40 && "text-slate-400 dark:text-zinc-500 bg-slate-100 dark:bg-zinc-800"
              ]}>
                {@content_length}/50
              </div>
            </div>

            <div class="flex items-center justify-end">
              <button
                type="submit"
                id="submit-item-btn"
                disabled={@content_length == 0 or @content_length > 50}
                class="flex items-center gap-2 px-6 py-3 bg-zinc-800 hover:bg-zinc-900 disabled:bg-slate-200 dark:disabled:bg-zinc-800 text-white disabled:text-slate-400 dark:disabled:text-zinc-600 font-bold rounded-2xl shadow-lg shadow-zinc-850/10 hover:shadow-zinc-850/20 disabled:shadow-none transition-all duration-200 transform active:scale-[0.98] disabled:transform-none cursor-pointer disabled:cursor-not-allowed"
              >
                <.icon name="hero-plus" class="size-4" /> {gettext("Add Bullet")}
              </button>
            </div>
          </.form>
        </div>
      </div>
    </Layouts.app>
    """
  end

  # Helper functions for the calendar logic

  defp select_date_helper(socket, date) do
    diary_items = Notebook.list_diary_items(date)
    changeset = Notebook.change_diary_item(%DiaryItem{date: date})
    total_volume = Notebook.get_workout_volume_for_date(date)

    socket =
      socket
      |> subscribe_to_date(date)
      |> assign(date: date)
      |> assign(content_length: 0)
      |> assign(form: to_form(changeset))
      |> assign(total_volume: total_volume)
      |> stream(:diary_items, diary_items, reset: true)

    target_month = Date.beginning_of_month(date)

    if Date.compare(target_month, socket.assigns.current_calendar_month) != :eq do
      update_calendar_month(socket, target_month)
    else
      socket
    end
  end

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

  defp assign_calendar_data(socket, start_date, end_date) do
    entry_dates = Notebook.list_calendar_data(start_date, end_date)
    socket |> assign(:calendar_entry_dates, entry_dates)
  end

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

  # Helper to format floats to decimal notation without scientific symbols
  defp format_volume(volume) when is_float(volume) do
    :erlang.float_to_binary(volume, [:compact, decimals: 1])
  end
  defp format_volume(volume) when is_integer(volume) do
    to_string(volume)
  end
  defp format_volume(_), do: "0.0"
end
