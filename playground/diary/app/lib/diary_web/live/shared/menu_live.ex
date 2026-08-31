defmodule DiaryWeb.MenuLive do
  @moduledoc """
  LiveView for the centralized application navigation menu.
  Displays options like Calendar, Timer, Stats, Settings, and Log out with Heroicons.
  """
  use DiaryWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    # Assign active_tab to 'menu' so navigation components know the current state
    socket =
      socket
      |> assign(:page_title, gettext("Menu"))
      |> assign(:active_tab, "menu")

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-2xl mx-auto space-y-6">
      <!-- Header Section with Back Navigation and Title -->
      <div class="flex items-center justify-between pb-4 border-b border-slate-200 dark:border-zinc-800">
        <div class="flex items-center gap-3">
          <div class="p-2 rounded-xl bg-zinc-100 dark:bg-zinc-800 text-zinc-700 dark:text-zinc-200">
            <.icon name="hero-bars-3" class="size-6" />
          </div>
          <div>
            <h1 class="text-xl font-black tracking-tight text-zinc-900 dark:text-zinc-100">
              {gettext("Application Menu")}
            </h1>
            <p class="text-xs text-slate-500 dark:text-zinc-400 font-medium">
              {gettext("Access features and manage your settings")}
            </p>
          </div>
        </div>

        <.link
          navigate={~p"/"}
          class="p-2.5 rounded-full bg-slate-100 dark:bg-zinc-800 text-slate-500 hover:text-slate-900 dark:hover:text-zinc-100 transition-colors"
          aria-label={gettext("Close")}
        >
          <.icon name="hero-x-mark" class="size-5" />
        </.link>
      </div>

      <!-- Grid Navigation Cards -->
      <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
        <!-- Calendar Link -->
        <.link
          navigate={~p"/"}
          class="group flex items-center gap-4 p-5 rounded-2xl bg-white dark:bg-zinc-900 border border-slate-100 dark:border-zinc-800/80 shadow-sm hover:shadow-md transition-all hover:border-zinc-300 dark:hover:border-zinc-700"
        >
          <div class="p-3 rounded-xl bg-indigo-50 dark:bg-indigo-950/50 text-indigo-600 dark:text-indigo-400 group-hover:scale-110 transition-transform">
            <.icon name="hero-calendar" class="size-6" />
          </div>
          <div>
            <h2 class="text-sm font-bold text-zinc-900 dark:text-zinc-100">
              {gettext("Calendar")}
            </h2>
            <p class="text-xs text-slate-400 dark:text-zinc-500 font-medium">
              {gettext("View and log daily workouts")}
            </p>
          </div>
        </.link>

        <!-- Timer Link -->
        <.link
          navigate={~p"/timer"}
          class="group flex items-center gap-4 p-5 rounded-2xl bg-white dark:bg-zinc-900 border border-slate-100 dark:border-zinc-800/80 shadow-sm hover:shadow-md transition-all hover:border-zinc-300 dark:hover:border-zinc-700"
        >
          <div class="p-3 rounded-xl bg-emerald-50 dark:bg-emerald-950/50 text-emerald-600 dark:text-emerald-400 group-hover:scale-110 transition-transform">
            <.icon name="hero-clock" class="size-6" />
          </div>
          <div>
            <h2 class="text-sm font-bold text-zinc-900 dark:text-zinc-100">
              {gettext("Timer")}
            </h2>
            <p class="text-xs text-slate-400 dark:text-zinc-500 font-medium">
              {gettext("Track workout intervals & rest")}
            </p>
          </div>
        </.link>

        <!-- Stats Link -->
        <.link
          navigate={~p"/stats"}
          class="group flex items-center gap-4 p-5 rounded-2xl bg-white dark:bg-zinc-900 border border-slate-100 dark:border-zinc-800/80 shadow-sm hover:shadow-md transition-all hover:border-zinc-300 dark:hover:border-zinc-700"
        >
          <div class="p-3 rounded-xl bg-amber-50 dark:bg-amber-950/50 text-amber-600 dark:text-amber-400 group-hover:scale-110 transition-transform">
            <.icon name="hero-chart-bar" class="size-6" />
          </div>
          <div>
            <h2 class="text-sm font-bold text-zinc-900 dark:text-zinc-100">
              {gettext("Stats")}
            </h2>
            <p class="text-xs text-slate-400 dark:text-zinc-500 font-medium">
              {gettext("Analyze progress & volume")}
            </p>
          </div>
        </.link>

        <!-- Account Settings Link -->
        <.link
          navigate={~p"/users/settings"}
          class="group flex items-center gap-4 p-5 rounded-2xl bg-white dark:bg-zinc-900 border border-slate-100 dark:border-zinc-800/80 shadow-sm hover:shadow-md transition-all hover:border-zinc-300 dark:hover:border-zinc-700"
        >
          <div class="p-3 rounded-xl bg-slate-100 dark:bg-zinc-800 text-slate-600 dark:text-zinc-300 group-hover:scale-110 transition-transform">
            <.icon name="hero-cog-6-tooth" class="size-6" />
          </div>
          <div>
            <h2 class="text-sm font-bold text-zinc-900 dark:text-zinc-100">
              {gettext("Settings")}
            </h2>
            <p class="text-xs text-slate-400 dark:text-zinc-500 font-medium">
              {gettext("Account and location settings")}
            </p>
          </div>
        </.link>
      </div>

      <!-- Quick Action / Logout Options Section -->
      <div class="pt-4 border-t border-slate-200 dark:border-zinc-800">
        <.link
          href={~p"/users/log-out"}
          method="delete"
          class="group flex items-center justify-between p-4 rounded-2xl bg-rose-50/50 dark:bg-rose-950/20 border border-rose-100 dark:border-rose-900/30 hover:bg-rose-100/50 dark:hover:bg-rose-900/40 transition-colors"
        >
          <div class="flex items-center gap-3">
            <div class="p-2.5 rounded-xl bg-rose-100 dark:bg-rose-900/50 text-rose-600 dark:text-rose-400">
              <.icon name="hero-arrow-right-on-rectangle" class="size-5" />
            </div>
            <span class="text-sm font-bold text-rose-700 dark:text-rose-300">
              {gettext("Log out")}
            </span>
          </div>
          <.icon name="hero-chevron-right" class="size-5 text-rose-400 group-hover:translate-x-0.5 transition-transform" />
        </.link>
      </div>
    </div>
    """
  end
end
