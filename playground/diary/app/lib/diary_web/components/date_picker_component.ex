defmodule DiaryWeb.DatePickerComponent do
  use Phoenix.Component

  import DiaryWeb.CoreComponents, only: [icon: 1]

  attr :date, :any, required: true
  attr :on_change, :string, default: "change_date", doc: "liveview event for date change"
  attr :on_adjust, :string, default: "adjust_date", doc: "liveview event for adjust date"
  attr :on_today, :string, default: "go_to_today", doc: "liveview event for go to today"

  slot :prev_button_content, doc: "Custom content for prev button"
  slot :next_button_content, doc: "Custom content for next button"
  slot :today_button_content, doc: "Custom content for today button"

  def date_navigator(assigns) do
    ~H"""
    <!-- Responsive container with smaller gap on mobile -->
    <div class="mt-6 flex items-center justify-between gap-1.5 sm:gap-2">
      <!-- Previous Day Button - Responsive padding and dark mode -->
      <button
        type="button"
        phx-click={@on_adjust}
        phx-value-days="-1"
        class="flex items-center justify-center p-2 sm:p-2.5 rounded-xl border border-zinc-200 dark:border-zinc-700 text-zinc-600 dark:text-zinc-400 hover:text-zinc-800 dark:hover:text-zinc-200 hover:border-zinc-300 dark:hover:border-zinc-650 hover:bg-zinc-50 dark:hover:bg-zinc-800/50 transition-all duration-200 cursor-pointer"
      >
        <%= render_slot(@prev_button_content) || ~H|<.icon name="hero-chevron-left" class="size-5" />| %>
      </button>
      <!-- Date Picker (Form & Input) - Responsive padding, font size, and dark mode -->
      <form phx-change={@on_change} id="date-select-form" class="flex-grow">
        <input
          type="date"
          name="date"
          value={Date.to_iso8601(@date)}
          id="date-picker-input"
          class="w-full text-center font-bold text-xs sm:text-sm text-zinc-700 dark:text-zinc-300 bg-white dark:bg-zinc-900 border border-zinc-200 dark:border-zinc-700 rounded-xl py-2 px-1.5 sm:px-4 focus:ring-2 focus:ring-zinc-800 focus:border-zinc-800 outline-none transition-all duration-200 cursor-pointer"
        />
      </form>
      <!-- Today Button - Responsive padding and dark mode -->
      <button
        type="button"
        phx-click={@on_today}
        class="flex items-center justify-center py-2 px-2 sm:px-4 rounded-xl border border-zinc-200 dark:border-zinc-700 text-xs sm:text-sm font-bold text-zinc-600 dark:text-zinc-400 hover:text-zinc-800 dark:hover:text-zinc-200 hover:border-zinc-300 dark:hover:border-zinc-650 hover:bg-zinc-50 dark:hover:bg-zinc-800/50 transition-all duration-200 cursor-pointer"
      >
        <%= render_slot(@today_button_content) || "Today" %>
      </button>
      <!-- Next Day Button - Responsive padding and dark mode -->
      <button
        type="button"
        phx-click={@on_adjust}
        phx-value-days="1"
        class="flex items-center justify-center p-2 sm:p-2.5 rounded-xl border border-zinc-200 dark:border-zinc-700 text-zinc-600 dark:text-zinc-400 hover:text-zinc-800 dark:hover:text-zinc-200 hover:border-zinc-300 dark:hover:border-zinc-650 hover:bg-zinc-50 dark:hover:bg-zinc-800/50 transition-all duration-200 cursor-pointer"
      >
        <%= render_slot(@next_button_content) || ~H|<.icon name="hero-chevron-right" class="size-5" />| %>
      </button>
    </div>
    """
  end


end
