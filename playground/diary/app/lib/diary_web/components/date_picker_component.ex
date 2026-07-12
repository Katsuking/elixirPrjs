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
    <div class="mt-6 flex items-center justify-between gap-2">
      <!-- Previous Day Button -->
      <button
        type="button"
        phx-click={@on_adjust}
        phx-value-days="-1"
        class="flex items-center justify-center p-2.5 rounded-xl border border-slate-200 text-slate-600 hover:text-indigo-600 hover:border-indigo-200 hover:bg-indigo-50/55 transition-all duration-200 cursor-pointer"
      >
        <%= render_slot(@prev_button_content) || ~H|<.icon name="hero-chevron-left" class="size-5" />| %>
      </button>
      <!-- Date Picker (Form & Input) -->
      <form phx-change={@on_change} id="date-select-form" class="flex-grow">
        <input
          type="date"
          name="date"
          value={Date.to_iso8601(@date)}
          id="date-picker-input"
          class="w-full text-center font-bold text-slate-700 bg-white border border-slate-200 rounded-xl py-2 px-4 focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 outline-none transition-all duration-200 cursor-pointer"
        />
      </form>
      <!-- Today Button -->
      <button
        type="button"
        phx-click={@on_today}
        class="flex items-center justify-center py-2 px-4 rounded-xl border border-slate-200 text-sm font-bold text-slate-600 hover:text-indigo-600 hover:border-indigo-200 hover:bg-indigo-50/55 transition-all duration-200 cursor-pointer"
      >
        <%= render_slot(@today_button_content) || "Today" %>
      </button>
      <!-- Next Day Button -->
      <button
        type="button"
        phx-click={@on_adjust}
        phx-value-days="1"
        class="flex items-center justify-center p-2.5 rounded-xl border border-slate-200 text-slate-600 hover:text-indigo-600 hover:border-indigo-200 hover:bg-indigo-50/55 transition-all duration-200 cursor-pointer"
      >
        <%= render_slot(@next_button_content) || ~H|<.icon name="hero-chevron-right" class="size-5" />| %>
      </button>
    </div>
    """
  end


end
