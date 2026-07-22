defmodule DiaryWeb.Components.Diary.CalendarComponent do
  @moduledoc """
  A reusable calendar component that displays month navigation and a day grid
  with mood icons and entry indicators.
  """
  use DiaryWeb, :html

  attr :current_calendar_month, Date, required: true
  attr :calendar_days, :list, required: true
  attr :calendar_moods, :map, required: true
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
    <div class="p-8 border-b border-slate-100 bg-slate-50/50">
      <!-- Month Selection Header -->
      <div class="flex items-center justify-between mb-6">
        <button
          type="button"
          phx-click={@on_prev_month}
          class="p-2.5 rounded-xl border border-slate-200 text-slate-600 hover:text-indigo-600 hover:border-indigo-200 hover:bg-indigo-50/55 transition-all duration-200 cursor-pointer"
        >
          <.icon name="hero-chevron-left" class="size-5" />
        </button>
        <span class="text-lg font-extrabold text-slate-800">
          {format_month_year(@current_calendar_month, @locale)}
        </span>
        <button
          type="button"
          phx-click={@on_next_month}
          class="p-2.5 rounded-xl border border-slate-200 text-slate-600 hover:text-indigo-600 hover:border-indigo-200 hover:bg-indigo-50/55 transition-all duration-200 cursor-pointer"
        >
          <.icon name="hero-chevron-right" class="size-5" />
        </button>
      </div>

      <!-- Weekday Headers -->
      <div class="grid grid-cols-7 gap-2 mb-2 text-center text-xs font-bold text-slate-400 uppercase tracking-wider">
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
            mood = Map.get(@calendar_moods, day)
            has_entries = MapSet.member?(@calendar_entry_dates, day)
          %>
          <button
            type="button"
            phx-click={@on_select_date}
            phx-value-date={Date.to_iso8601(day)}
            class={[
              "relative flex flex-col items-center justify-between p-1.5 h-16 w-full rounded-2xl border transition-all duration-200 cursor-pointer",
              is_selected && "border-indigo-600 bg-indigo-50/30 ring-2 ring-indigo-600/20 shadow-md",
              !is_selected && is_today && "border-indigo-200 bg-indigo-50/10",
              !is_selected && !is_today && "border-slate-100 bg-white hover:border-slate-300 hover:bg-slate-50",
              !is_current_month && "opacity-40"
            ]}
          >
            <!-- Day Number -->
            <span class={[
              "text-xs font-bold",
              is_selected && "text-indigo-600",
              !is_selected && is_current_month && "text-slate-700",
              !is_current_month && "text-slate-400"
            ]}>
              {day.day}
            </span>

            <!-- Mood SVG -->
            <div class="flex-grow flex items-center justify-center min-h-[24px]">
              <%= if mood do %>
                <img
                  src={"/images/#{mood_image_name(mood.status)}.svg"}
                  class="w-6 h-6 object-contain hover:scale-110 transition-transform duration-150"
                  title={mood.status}
                />
              <% end %>
            </div>

            <!-- Entries Indicator (Dot) -->
            <div class="h-1 flex items-center justify-center">
              <%= if has_entries do %>
                <span class={[
                  "w-1.5 h-1.5 rounded-full block",
                  is_selected && "bg-indigo-600",
                  !is_selected && "bg-slate-400"
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

  # Helper to convert a mood status into its corresponding SVG filename.
  defp mood_image_name("very good"), do: "very_good"
  defp mood_image_name("on fire"), do: "on_fire"
  defp mood_image_name(status), do: status
end
