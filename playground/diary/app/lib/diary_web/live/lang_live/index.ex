defmodule DiaryWeb.LangLive.Index do
  use DiaryWeb, :live_view

  def mount(_params, _session, socket) do
    {:ok, assign(socket, :page_title, "Language App")}
  end

  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-2xl px-4 py-8">
      <div class="rounded-xl border border-base-300 bg-base-100 p-6 shadow-lg">
        <div class="flex items-center justify-between border-b border-base-200 pb-4">
          <h1 class="text-2xl font-bold text-primary">🌐 Language App</h1>
          <span class="badge badge-outline">lang.wayup.cc</span>
        </div>

        <div class="mt-6 space-y-4">
          <p class="text-base-content/80">
            Welcome to the Language App subdomain!
          </p>

          <div class="rounded-lg bg-base-200 p-4">
            <h2 class="text-sm font-semibold text-base-content/60">Logged in User</h2>
            <p class="mt-1 font-mono text-lg font-bold text-secondary">
              <%= @current_scope.user.email %>
            </p>
          </div>

          <div class="flex justify-end pt-4">
            <.link href={~p"/users/log-out"} method="delete" class="btn btn-outline btn-error btn-sm">
              Log out
            </.link>
          </div>
        </div>
      </div>
    </div>
    """
  end
end
