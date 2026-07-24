defmodule DiaryWeb.Layouts do
  @moduledoc """
  This module holds layouts and related functionality
  used by your application.
  """
  use DiaryWeb, :html

  # Embed all files in layouts/* within this module.
  # The default root.html.heex file contains the HTML
  # skeleton of your application, namely HTML headers
  # and other static content.
  embed_templates "layouts/*"

  @doc """
  Renders your app layout.

  This function is typically invoked from every template,
  and it often contains your application menu, sidebar,
  or similar.

  ## Examples

      <Layouts.app flash={@flash}>
        <h1>Content</h1>
      </Layouts.app>

  """
    attr :flash, :map, required: true, doc: "the map of flash messages"
  attr :active_tab, :string, default: nil, doc: "currently active navigation tab"

  attr :current_scope, :map,
    default: nil,
    doc: "the current [scope](https://phoenix.hexdocs.pm/scopes.html)"

  slot :inner_block, required: true

  def app(assigns) do
    ~H"""
    <div class="h-screen overflow-hidden flex flex-col md:flex-row bg-slate-50 dark:bg-zinc-950 text-slate-800 dark:text-zinc-100">

      <!-- Desktop Sidebar (hidden on mobile) -->
      <aside class="hidden md:flex md:flex-col md:w-64 bg-white dark:bg-zinc-900 border-r border-slate-100 dark:border-zinc-850 p-6 space-y-8 flex-shrink-0">
        <!-- Logo / Title -->
        <div class="flex items-center gap-3">
          <span class="text-3xl select-none">💪</span>
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
        </nav>

        <!-- Footer / Theme Toggle -->
        <div class="pt-4 border-t border-slate-100 dark:border-zinc-800 flex items-center justify-between">
          <span class="text-[10px] font-bold text-slate-400">v1.0.0</span>
          <.theme_toggle />
        </div>
      </aside>

      <!-- Mobile Top Bar (hidden on desktop) -->
      <header class="md:hidden flex items-center justify-between px-6 py-4 bg-white dark:bg-zinc-900 border-b border-slate-100 dark:border-zinc-850 sticky top-0 z-40">
        <div class="flex items-center gap-2">
          <span class="text-2xl select-none">💪</span>
          <span class="text-sm font-black tracking-tight text-zinc-800 dark:text-zinc-100">FITNESS DIARY</span>
        </div>
        <.theme_toggle />
      </header>

      <!-- Main Content Area -->
      <main class="flex-1 min-w-0 overflow-y-auto pb-24 md:pb-12">
        <div class="max-w-5xl mx-auto px-4 py-8 sm:px-6 lg:px-8">
          {render_slot(@inner_block)}
        </div>
      </main>

      <!-- Mobile Bottom Navigation (hidden on desktop) -->
      <nav class="md:hidden fixed bottom-0 left-0 right-0 bg-white dark:bg-zinc-900 border-t border-slate-100 dark:border-zinc-850 flex items-center justify-around py-3 px-6 z-40 pb-safe shadow-lg">
        <.link
          navigate={~p"/"}
          class={[
            "flex flex-col items-center gap-1 text-[10px] font-black cursor-pointer transition-all duration-200",
            @active_tab == "diary" && "text-zinc-800 dark:text-zinc-100 scale-105",
            @active_tab != "diary" && "text-slate-400 dark:text-zinc-500 hover:text-slate-600"
          ]}
        >
          <.icon name="hero-calendar" class="size-6" />
          {gettext("Calendar")}
        </.link>
        <.link
          navigate={~p"/stats"}
          class={[
            "flex flex-col items-center gap-1 text-[10px] font-black cursor-pointer transition-all duration-200",
            @active_tab == "stats" && "bg-zinc-800 dark:text-zinc-100 scale-105",
            @active_tab != "stats" && "text-slate-400 dark:text-zinc-500 hover:text-slate-600"
          ]}
        >
          <.icon name="hero-chart-bar" class="size-6" />
          {gettext("Stats")}
        </.link>
      </nav>

    </div>

    <.flash_group flash={@flash} />
    """
  end

  @doc """
  Shows the flash group with standard titles and content.

  ## Examples

      <.flash_group flash={@flash} />
  """
  attr :flash, :map, required: true, doc: "the map of flash messages"
  attr :id, :string, default: "flash-group", doc: "the optional id of flash container"

  def flash_group(assigns) do
    ~H"""
    <div id={@id} aria-live="polite">
      <.flash kind={:info} flash={@flash} />
      <.flash kind={:error} flash={@flash} />

      <.flash
        id="client-error"
        kind={:error}
        title={gettext("We can't find the internet")}
        phx-disconnected={
          show(".phx-client-error #client-error")
          |> JS.remove_attribute("hidden", to: ".phx-client-error #client-error")
        }
        phx-connected={hide("#client-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        {gettext("Attempting to reconnect")}
        <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
      </.flash>

      <.flash
        id="server-error"
        kind={:error}
        title={gettext("Something went wrong!")}
        phx-disconnected={
          show(".phx-server-error #server-error")
          |> JS.remove_attribute("hidden", to: ".phx-server-error #server-error")
        }
        phx-connected={hide("#server-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        {gettext("Attempting to reconnect")}
        <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
      </.flash>
    </div>
    """
  end

  @doc """
  Provides dark vs light theme toggle based on themes defined in app.css.

  See <head> in root.html.heex which applies the theme before page load.
  """
  def theme_toggle(assigns) do
    ~H"""
    <div class="card relative flex flex-row items-center border-2 border-base-300 bg-base-300 rounded-full">
      <div class="absolute w-1/3 h-full rounded-full border-1 border-base-200 bg-base-100 brightness-200 left-0 [[data-theme=light]_&]:left-1/3 [[data-theme=dark]_&]:left-2/3 [[data-theme-source=system]_&]:!left-0 transition-[left]" />

      <button
        class="flex p-2 cursor-pointer w-1/3"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="system"
      >
        <.icon name="hero-computer-desktop-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>

      <button
        class="flex p-2 cursor-pointer w-1/3"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="light"
      >
        <.icon name="hero-sun-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>

      <button
        class="flex p-2 cursor-pointer w-1/3"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="dark"
      >
        <.icon name="hero-moon-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>
    </div>
    """
  end
end
