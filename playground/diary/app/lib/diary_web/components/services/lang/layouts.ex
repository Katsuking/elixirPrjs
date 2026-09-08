defmodule DiaryWeb.Services.Lang.Layouts do
  @moduledoc """
  Holds application layouts and UI structure dedicated to the Language service (lang.wayup.cc).
  """
  use DiaryWeb, :html

  # Import shared layout elements (flash_group, theme_toggle) from global Layouts module
  import DiaryWeb.Layouts, only: [flash_group: 1, theme_toggle: 1]

  @doc """
  Renders the main application layout for the Language service.
  """
  attr :flash, :map, required: true, doc: "the map of flash messages"
  attr :active_tab, :string, default: "home", doc: "currently active navigation tab"

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
          <div class="flex size-9 items-center justify-center rounded-2xl bg-indigo-600 text-white shadow-md shadow-indigo-500/20">
            <.icon name="hero-language" class="size-5" />
          </div>
          <div>
            <h1 class="text-base font-black tracking-tight text-zinc-800 dark:text-zinc-100">LANGUAGE DIARY</h1>
            <p class="text-[9px] font-bold text-indigo-500 dark:text-indigo-400 tracking-wider uppercase">Master Your Languages</p>
          </div>
        </div>

        <!-- Navigation Links -->
        <nav class="flex-1 space-y-2">
          <.link
            navigate={~p"/"}
            class={[
              "flex items-center gap-3 px-4 py-3 rounded-2xl font-extrabold text-sm transition-all duration-200 cursor-pointer",
              @active_tab == "home" && "bg-indigo-600 text-white shadow-lg shadow-indigo-600/20",
              @active_tab != "home" && "text-slate-600 dark:text-zinc-400 hover:bg-slate-50 dark:hover:bg-zinc-800/50 hover:text-zinc-800 dark:hover:text-zinc-100"
            ]}
          >
            <.icon name="hero-home" class="size-5" />
            {gettext("Home")}
          </.link>
          <.link
            navigate={~p"/users/settings"}
            class={[
              "flex items-center gap-3 px-4 py-3 rounded-2xl font-extrabold text-sm transition-all duration-200 cursor-pointer",
              @active_tab == "settings" && "bg-indigo-600 text-white shadow-lg shadow-indigo-600/20",
              @active_tab != "settings" && "text-slate-600 dark:text-zinc-400 hover:bg-slate-50 dark:hover:bg-zinc-800/50 hover:text-zinc-800 dark:hover:text-zinc-100"
            ]}
          >
            <.icon name="hero-cog-6-tooth" class="size-5" />
            {gettext("Settings")}
          </.link>
        </nav>

        <!-- Footer / Theme Toggle -->
        <div class="pt-4 border-t border-slate-100 dark:border-zinc-800 flex items-center justify-between">
          <span class="text-[10px] font-bold text-slate-400">lang v0.0.1</span>
          <.theme_toggle />
        </div>
      </aside>

      <!-- Mobile Top Bar (hidden on desktop) -->
      <header class="md:hidden flex items-center justify-between px-6 py-4 bg-white dark:bg-zinc-900 border-b border-slate-100 dark:border-zinc-850 sticky top-0 z-40">
        <div class="flex items-center gap-2">
          <div class="flex size-7 items-center justify-center rounded-xl bg-indigo-600 text-white">
            <.icon name="hero-language" class="size-4" />
          </div>
          <span class="text-sm font-black tracking-tight text-zinc-800 dark:text-zinc-100">LANGUAGE DIARY</span>
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

    </div>

    <.flash_group flash={@flash} />
    """
  end
end
