defmodule HelloLiveviewWeb.QuizLive.Show do
  use HelloLiveviewWeb, :live_view

  alias HelloLiveview.Quizzes

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    quiz_set = Quizzes.get_quiz_set_with_questions!(id)
    current_user = socket.assigns.current_scope.user

    {:ok, attempt} = Quizzes.create_quiz_attempt(%{
      user_id: current_user.id,
      quiz_set_id: quiz_set.id
    })

    {:ok,
     socket
     |> assign(:quiz_set, quiz_set)
     |> assign(:attempt, attempt)
     |> assign(:current_question_index, 0)
     |> assign(:selected_option_id, nil)
     |> assign(:show_explanation, false)}
  end

  @impl true
  def handle_event("select_option", %{"id" => option_id}, socket) do
    {:noreply, assign(socket, :selected_option_id, option_id)}
  end

  @impl true
  def handle_event("submit", _, socket) do
    # Save the answer to DB
    attempt = socket.assigns.attempt
    current_question = Enum.at(socket.assigns.quiz_set.questions, socket.assigns.current_question_index)
    selected_option_id = socket.assigns.selected_option_id

    Quizzes.save_user_answer(attempt.id, current_question.id, selected_option_id)

    {:noreply, assign(socket, :show_explanation, true)}
  end

  @impl true
  def handle_event("next_question", _, socket) do
    quiz_set = socket.assigns.quiz_set
    next_index = socket.assigns.current_question_index + 1

    if next_index < length(quiz_set.questions) do
      {:noreply,
       socket
       |> assign(:current_question_index, next_index)
       |> assign(:selected_option_id, nil)
       |> assign(:show_explanation, false)}
    else
      # Quiz finished
      {:ok, final_attempt} = Quizzes.complete_quiz_attempt(socket.assigns.attempt)

      score_text = "#{final_attempt.score} / #{length(quiz_set.questions)}"

      {:noreply,
       socket
       |> put_flash(:info, "クイズ完了！お疲れ様でした。正解数: #{score_text}")
       |> redirect(to: ~p"/quizzes")}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-3xl mx-auto p-6 bg-white dark:bg-zinc-800 rounded-lg shadow-md mt-10 border border-zinc-100 dark:border-zinc-700">
      <div class="mb-8">
        <h1 class="text-3xl font-bold mb-2 text-zinc-900 dark:text-zinc-100"><%= @quiz_set.title %></h1>
        <p class="text-zinc-600 dark:text-zinc-400"><%= @quiz_set.description %></p>
      </div>

      <%= if length(@quiz_set.questions) > 0 do %>
        <% current_question = Enum.at(@quiz_set.questions, @current_question_index) %>

        <.question_header
          index={@current_question_index}
          total={length(@quiz_set.questions)}
          text={current_question.text}
        />

        <div class="space-y-3 mt-6">
          <%= for option <- current_question.options do %>
            <.option_item
              option={option}
              selected_id={@selected_option_id}
              show_explanation={@show_explanation}
            />
          <% end %>
        </div>

        <%= if @show_explanation do %>
          <.explanation_box explanation={current_question.explanation} />

          <div class="mt-8 flex justify-end">
            <button phx-click="next_question" class="px-6 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 font-medium transition-colors">
              <%= if @current_question_index + 1 == length(@quiz_set.questions), do: "終了", else: "次の問題へ" %>
            </button>
          </div>
        <% else %>
          <div class="mt-8 flex justify-end">
            <button
              phx-click="submit"
              disabled={is_nil(@selected_option_id)}
              class={"px-6 py-2 rounded-lg font-medium transition-colors " <>
                if is_nil(@selected_option_id), do: "bg-zinc-300 dark:bg-zinc-700 text-zinc-500 dark:text-zinc-400 cursor-not-allowed", else: "bg-blue-600 text-white hover:bg-blue-700"
              }>
              回答する
            </button>
          </div>
        <% end %>
      <% else %>
        <.empty_state />
      <% end %>
    </div>
    """
  end

  defp question_header(assigns) do
    ~H"""
    <div>
      <div class="mb-4">
        <span class="text-sm font-semibold text-blue-500">問題 <%= @index + 1 %> / <%= @total %></span>
      </div>
      <h2 class="text-xl font-medium text-zinc-900 dark:text-zinc-100"><%= @text %></h2>
    </div>
    """
  end

  defp option_item(assigns) do
    ~H"""
    <% is_selected = @selected_id == @option.id %>
    <% is_correct = @option.is_correct %>
    <div
      phx-click={if not @show_explanation, do: "select_option"}
      phx-value-id={@option.id}
      class={"p-4 border rounded-lg cursor-pointer transition-colors duration-200 " <>
        if @show_explanation do
          if is_correct do
            "bg-green-100 dark:bg-green-900/30 border-green-500 text-green-900 dark:text-green-100"
          else
            if is_selected do
              "bg-red-100 dark:bg-red-900/30 border-red-500 text-red-900 dark:text-red-100"
            else
              "bg-zinc-50 dark:bg-zinc-900/50 border-zinc-200 dark:border-zinc-700 text-zinc-500 dark:text-zinc-400"
            end
          end
        else
          if is_selected do
            "bg-blue-50 dark:bg-blue-900/30 border-blue-500 text-blue-900 dark:text-blue-100"
          else
            "bg-white dark:bg-zinc-800 border-zinc-300 dark:border-zinc-600 text-zinc-900 dark:text-zinc-200 hover:bg-zinc-50 dark:hover:bg-zinc-700"
          end
        end
      }
    >
      <div class="flex items-center">
        <div class={"w-5 h-5 rounded-full border mr-3 flex items-center justify-center " <>
          if is_selected, do: "border-blue-500", else: "border-zinc-400"}>
          <%= if is_selected do %>
            <div class="w-3 h-3 rounded-full bg-blue-500"></div>
          <% end %>
        </div>
        <span><%= @option.text %></span>

        <%= if @show_explanation do %>
          <span class="ml-auto font-bold">
            <%= if is_correct, do: "✓", else: (if is_selected, do: "✗") %>
          </span>
        <% end %>
      </div>
    </div>
    """
  end

  defp explanation_box(assigns) do
    ~H"""
    <div class="mt-8 p-4 bg-blue-50 dark:bg-blue-900/20 rounded-lg border border-blue-200 dark:border-blue-800">
      <h3 class="font-bold text-blue-800 dark:text-blue-300 mb-2">解説:</h3>
      <p class="text-blue-900 dark:text-blue-200"><%= @explanation || "解説はありません。" %></p>
    </div>
    """
  end

  defp empty_state(assigns) do
    ~H"""
    <div class="p-8 text-center bg-zinc-50 dark:bg-zinc-900/50 rounded-lg border border-zinc-200 dark:border-zinc-700">
      <p class="text-zinc-500 dark:text-zinc-400">まだ問題が登録されていません。</p>
    </div>
    """
  end
end
