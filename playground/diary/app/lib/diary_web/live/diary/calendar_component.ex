defmodule DiaryWeb.Diary.CalendarComponent do
  @moduledoc """
  A reusable calendar component that displays month navigation and a day grid
  with entry indicators.
  """
  use DiaryWeb, :html

  attr :current_calendar_month, Date, required: true
  attr :calendar_days, :list, required: true
  attr :calendar_entry_dates, :any, required: true # MapSet of Dates
  attr :date, Date, required: true
  attr :locale, :string, required: true
  attr :on_prev_month, :string, default: "prev_month"
  attr :on_next_month, :string, default: "next_month"
  attr :on_select_date, :string, default: "select_date"

  @doc """
  Renders the monthly calendar grid and controls.
  """
  def calendar(assigns) do
    ~H"""
    <div class="p-8 border-b border-slate-100 dark:border-zinc-800 bg-slate-50/30">
      <!-- Month Selection Header -->
      <div class="flex items-center justify-between mb-6">
        <button
          type="button"
          phx-click={@on_prev_month}
          class="p-2.5 rounded-xl border border-zinc-200 dark:border-zinc-700 text-zinc-600 dark:text-zinc-400 hover:text-zinc-800 hover:border-zinc-300 dark:hover:border-zinc-650 hover:bg-zinc-50 dark:hover:bg-zinc-800/50 transition-all duration-200 cursor-pointer"
        >
          <.icon name="hero-chevron-left" class="size-5" />
        </button>
        <span class="text-lg font-black text-zinc-800 dark:text-zinc-100">
          {format_month_year(@current_calendar_month, @locale)}
        </span>
        <button
          type="button"
          phx-click={@on_next_month}
          class="p-2.5 rounded-xl border border-zinc-200 dark:border-zinc-700 text-zinc-600 dark:text-zinc-400 hover:text-zinc-800 hover:border-zinc-300 dark:hover:border-zinc-650 hover:bg-zinc-50 dark:hover:bg-zinc-800/50 transition-all duration-200 cursor-pointer"
        >
          <.icon name="hero-chevron-right" class="size-5" />
        </button>
      </div>

      <!-- Weekday Headers -->
      <div class="grid grid-cols-7 gap-2 mb-2 text-center text-[10px] font-black text-zinc-400 uppercase tracking-widest">
        <div><%= gettext("Sun") %></div>
        <div><%= gettext("Mon") %></div>
        <div><%= gettext("Tue") %></div>
        <div><%= gettext("Wed") %></div>
        <div><%= gettext("Thu") %></div>
        <div><%= gettext("Fri") %></div>
        <div><%= gettext("Sat") %></div>
      </div>

      <!-- Calendar Days Grid -->
      <div class="grid grid-cols-7 gap-2">
        <%= for day <- @calendar_days do %>
          <%
            is_selected = Date.compare(day, @date) == :eq
            is_today = Date.compare(day, Date.utc_today()) == :eq
            is_current_month = day.month == @current_calendar_month.month
            has_entries = MapSet.member?(@calendar_entry_dates, day)
          %>
          <button
            type="button"
            phx-click={@on_select_date}
            phx-value-date={Date.to_iso8601(day)}
            class={[
              "relative flex flex-col items-center justify-between p-1.5 h-16 w-full rounded-2xl border transition-all duration-200 cursor-pointer",
              is_selected && "border-zinc-800 bg-zinc-50 dark:bg-zinc-800 ring-2 ring-zinc-800/10 shadow-md",
              !is_selected && is_today && "border-zinc-300 dark:border-zinc-700 bg-zinc-50/20",
              !is_selected && !is_today && "border-zinc-100 dark:border-zinc-850 bg-white dark:bg-zinc-900 hover:border-zinc-300 dark:hover:border-zinc-700 hover:bg-zinc-50 dark:hover:bg-zinc-800/30",
              !is_current_month && "opacity-40"
            ]}
          >
            <!-- Day Number -->
            <span class={[
              "text-xs font-bold",
              is_selected && "text-zinc-800 dark:text-zinc-100",
              !is_selected && is_current_month && "text-zinc-700 dark:text-zinc-300",
              !is_current_month && "text-zinc-400"
            ]}>
              {day.day}
            </span>

            <!-- Spacer Area -->
            <div class="flex-grow flex items-center justify-center min-h-[24px]"></div>

            <!-- Entries Indicator (Dot) -->
            <div class="h-1 flex items-center justify-center">
              <%= if has_entries do %>
                <span class={[
                  "w-1.5 h-1.5 rounded-full block",
                  is_selected && "bg-zinc-800 dark:bg-zinc-100",
                  !is_selected && "bg-zinc-400 dark:bg-zinc-500"
                ]}></span>
              <% end %>
            </div>
          </button>
        <% end %>
      </div>
    </div>
    """
  end

  # Helper to format the calendar month header according to the locale.
  defp format_month_year(date, locale) do
    case locale do
      "ja" ->
        "#{date.year}年 #{date.month}月"

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

        "#{month_name} #{date.year}"
    end
  end
end
