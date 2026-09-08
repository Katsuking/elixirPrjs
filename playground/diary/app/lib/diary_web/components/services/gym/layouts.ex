defmodule DiaryWeb.Services.Gym.Layouts do
  @moduledoc """
  Holds application layouts and UI structure dedicated to the Gym service (gym.wayup.cc).
  """
  use DiaryWeb, :html

  # Import shared layout elements (flash_group, theme_toggle) from global Layouts module
  import DiaryWeb.Layouts, only: [flash_group: 1, theme_toggle: 1]

  @doc """
  Renders the main application layout for the Gym service.
  """
  attr :flash, :map, required: true, doc: "the map of flash messages"
  attr :active_tab, :string, default: nil, doc: "currently active navigation tab"

  attr :current_scope, :map,
    default: nil,
    doc: "the current scope struct"

  def app(assigns) do
    ~H"""
    <div class="h-screen overflow-hidden flex flex-col md:flex-row bg-slate-50 dark:bg-zinc-950 text-slate-800 dark:text-zinc-100">

      <!-- Desktop Sidebar (hidden on mobile) -->
      <aside class="hidden md:flex md:flex-col md:w-64 bg-white dark:bg-zinc-900 border-r border-slate-100 dark:border-zinc-850 p-6 space-y-8 flex-shrink-0">
        <!-- Logo / Title -->
        <div class="flex items-center gap-3">
          <img src={~p"/images/power.svg"} class="w-8 h-auto" alt="Fitness Diary" />
          <div>
            <h1 class="text-base font-black tracking-tight text-zinc-800 dark:text-zinc-100">FITNESS DIARY</h1>
            <p class="text-[9px] font-bold text-slate-400 tracking-wider uppercase">Elevate Your Day</p>
          </div>
        </div>

        <!-- Navigation Links -->
        <nav class="flex-1 space-y-2">
          <.link
            navigate={~p"/"}
            class={[
              "flex items-center gap-3 px-4 py-3 rounded-2xl font-extrabold text-sm transition-all duration-200 cursor-pointer",
              @active_tab == "diary" && "bg-zinc-800 text-white shadow-lg shadow-zinc-850/10",
              @active_tab != "diary" && "text-slate-600 dark:text-zinc-400 hover:bg-slate-50 dark:hover:bg-zinc-800/50 hover:text-zinc-800 dark:hover:text-zinc-100"
            ]}
          >
            <.icon name="hero-calendar" class="size-5" />
            {gettext("Calendar")}
          </.link>
          <.link
            navigate={~p"/timer"}
            class={[
              "flex items-center gap-3 px-4 py-3 rounded-2xl font-extrabold text-sm transition-all duration-200 cursor-pointer",
              @active_tab == "timer" && "bg-zinc-800 text-white shadow-lg shadow-zinc-850/10",
              @active_tab != "timer" && "text-slate-600 dark:text-zinc-400 hover:bg-slate-50 dark:hover:bg-zinc-800/50 hover:text-zinc-800 dark:hover:text-zinc-100"
            ]}
          >
            <.icon name="hero-clock" class="size-5" />
            {gettext("Timer")}
          </.link>
          <.link
            navigate={~p"/stats"}
            class={[
              "flex items-center gap-3 px-4 py-3 rounded-2xl font-extrabold text-sm transition-all duration-200 cursor-pointer",
              @active_tab == "stats" && "bg-zinc-800 text-white shadow-lg shadow-zinc-850/10",
              @active_tab != "stats" && "text-slate-600 dark:text-zinc-400 hover:bg-slate-50 dark:hover:bg-zinc-800/50 hover:text-zinc-800 dark:hover:text-zinc-100"
            ]}
          >
            <.icon name="hero-chart-bar" class="size-5" />
            {gettext("Stats")}
          </.link>
          <.link
            navigate={~p"/menu"}
            class={[
              "flex items-center gap-3 px-4 py-3 rounded-2xl font-extrabold text-sm transition-all duration-200 cursor-pointer",
              @active_tab == "menu" && "bg-zinc-800 text-white shadow-lg shadow-zinc-850/10",
              @active_tab != "menu" && "text-slate-600 dark:text-zinc-400 hover:bg-slate-50 dark:hover:bg-zinc-800/50 hover:text-zinc-800 dark:hover:text-zinc-100"
            ]}
          >
            <.icon name="hero-bars-3" class="size-5" />
            {gettext("Menu")}
          </.link>
        </nav>

        <!-- Footer / Theme Toggle -->
        <div class="pt-4 border-t border-slate-100 dark:border-zinc-850 flex items-center justify-between">
          <span class="text-[10px] font-bold text-slate-400">v0.0.2</span>
          <.theme_toggle />
        </div>
      </aside>

      <!-- Mobile Top Bar (hidden on desktop) -->
      <header class="md:hidden flex items-center justify-between px-6 py-4 bg-white dark:bg-zinc-900 border-b border-slate-100 dark:border-zinc-850 sticky top-0 z-40">
        <div class="flex items-center gap-2">
          <img src={~p"/images/power.svg"} class="w-8 h-auto" alt="Fitness Diary" />
          <span class="text-sm font-black tracking-tight text-zinc-800 dark:text-zinc-100">FITNESS DIARY</span>
        </div>
        <.theme_toggle />
      </header>

      <!-- Main Content Area -->
      <main class="flex-1 min-w-0 overflow-y-auto pb-24 md:pb-12">
        <.under_development_banner />

        <div class="max-w-5xl mx-auto px-4 py-8 sm:px-6 lg:px-8">
          {@inner_content}
        </div>
      </main>

      <!-- Mobile Floating Action Button for Menu (hidden on desktop) -->
      <.link
        navigate={~p"/menu"}
        class={[
          "md:hidden fixed bottom-6 right-6 z-50 flex items-center justify-center p-3.5 rounded-full shadow-2xl transition-all duration-200 cursor-pointer active:scale-95",
          @active_tab == "menu" && "bg-zinc-900 text-white dark:bg-zinc-100 dark:text-zinc-900 ring-4 ring-zinc-300 dark:ring-zinc-700",
          @active_tab != "menu" && "bg-zinc-800 text-white hover:bg-zinc-700 dark:bg-zinc-100 dark:text-zinc-900 dark:hover:bg-white shadow-zinc-900/30"
        ]}
        aria-label={gettext("Menu")}
      >
        <.icon name="hero-bars-3" class="size-6" />
      </.link>

    </div>

    <.flash_group flash={@flash} />
    """
  end
end
