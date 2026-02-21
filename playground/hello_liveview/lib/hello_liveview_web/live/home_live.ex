defmodule HelloLiveviewWeb.HomeLive do
  use HelloLiveviewWeb, :live_view

  alias HelloLiveview.Quizzes

  @impl true
  def mount(_params, _session, socket) do
    quiz_sets = Quizzes.list_quiz_sets()

    recent_attempts =
      if socket.assigns[:current_scope] && socket.assigns.current_scope.user do
        Quizzes.list_recent_user_attempts(socket.assigns.current_scope.user.id)
      else
        []
      end

    {:ok,
     socket
     |> assign(:quiz_sets, quiz_sets)
     |> assign(:recent_attempts, recent_attempts)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="px-4 py-10 sm:px-6 sm:py-28 lg:px-8 xl:px-50 xl:py-32 w-full max-w-7xl mx-auto">
      <div class="mb-12">
        <h1 class="text-4xl font-bold tracking-tight text-zinc-900 dark:text-zinc-100">クイズ一覧</h1>
        <p class="mt-4 text-lg text-zinc-600 dark:text-zinc-400">Phoenix LiveViewで作成されたクイズアプリケーションのデモです。</p>
      </div>

      <div class="mt-12 bg-white dark:bg-zinc-800 p-6 rounded-xl shadow-sm border border-zinc-100 dark:border-zinc-700">
        <h2 class="text-2xl font-bold tracking-tight text-zinc-900 dark:text-zinc-100">挑戦できるクイズ</h2>
        <p class="mt-2 text-zinc-600 dark:text-zinc-400">問題集を選んで知識を試してみましょう。</p>

        <div class="mt-6 grid gap-4 grid-cols-1 sm:grid-cols-2">
          <%= for quiz <- @quiz_sets do %>
            <.quiz_card quiz={quiz} />
          <% end %>

          <%= if Enum.empty?(@quiz_sets) do %>
            <div class="col-span-full p-4 text-center text-zinc-500 dark:text-zinc-400 bg-zinc-50 dark:bg-zinc-900 rounded-lg">
              クイズがまだ登録されていません。seedスクリプトを実行してください。
            </div>
          <% end %>
        </div>
      </div>

      <%= if @recent_attempts != [] do %>
        <div class="mt-8 bg-white dark:bg-zinc-800 p-6 rounded-xl shadow-sm border border-zinc-100 dark:border-zinc-700">
          <h2 class="text-2xl font-bold tracking-tight text-zinc-900 dark:text-zinc-100">最近の成績</h2>

          <div class="mt-6 space-y-4">
            <%= for attempt <- @recent_attempts do %>
              <div class="p-4 border border-zinc-200 dark:border-zinc-700 rounded-lg flex justify-between items-center bg-zinc-50 dark:bg-zinc-900/50">
                <div>
                  <h3 class="font-semibold text-zinc-900 dark:text-zinc-100"><%= attempt.quiz_set.title %></h3>
                  <p class="text-sm text-zinc-500 dark:text-zinc-400">
                    <%= Calendar.strftime(attempt.completed_at, "%Y/%m/%d %H:%M") %> に完了
                  </p>
                </div>
                <div class="text-xl font-bold text-blue-600 dark:text-blue-400">
                  スコア: <%= attempt.score %>
                </div>
              </div>
            <% end %>
          </div>
        </div>
      <% end %>
    </div>
    """
  end

  def quiz_card(assigns) do
    ~H"""
    <a href={~p"/quizzes/#{@quiz.id}"} class="group block p-4 border rounded-lg hover:border-blue-500 hover:bg-blue-50 dark:hover:bg-blue-900/20 transition-colors border-zinc-200 dark:border-zinc-700">
      <h3 class="font-semibold text-lg text-zinc-900 dark:text-zinc-100 group-hover:text-blue-600"><%= @quiz.title %></h3>
      <p class="mt-1 text-sm text-zinc-500 dark:text-zinc-400"><%= @quiz.description %></p>
    </a>
    """
  end
end
