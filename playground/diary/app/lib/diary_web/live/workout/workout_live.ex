defmodule DiaryWeb.WorkoutLive do
  @moduledoc """
  LiveView for filtering exercises by muscle group and logging workout sets, weight, and reps.
  """
  use DiaryWeb, :live_view
  use Gettext, backend: DiaryWeb.Gettext

  alias Diary.Notebook
  alias Diary.WorkoutMaster

  @impl true
  def mount(%{"date" => date_str}, session, socket) do
    # Fetch user_id from socket.assigns.current_scope.user (assigned by require_authenticated)
    user_id = socket.assigns.current_scope.user.id
    # Retrieve locale saved by the session (fallback to "en")
    locale = session["locale"] || "en"
    Gettext.put_locale(DiaryWeb.Gettext, locale)

    # Parse target date, falling back to today if invalid
    date =
      case Date.from_iso8601(date_str) do
        {:ok, parsed_date} -> parsed_date
        _ -> Date.utc_today()
      end

    # Subscribe to PubSub for real-time synchronization on this date for this user
    if connected?(socket) do
      Phoenix.PubSub.subscribe(Diary.PubSub, "diary:#{user_id}:#{date}")
    end

    # Group exercises by primary muscle group (the first group defined in their ratios)
    exercises_by_group =
      WorkoutMaster.exercises()
      |> Enum.group_by(fn exercise ->
        case WorkoutMaster.exercise_ratios(exercise) do
          [first | _] -> first.general
          _ -> "Other"
        end
      end)

    # List of all muscle groups that have exercises defined
    muscle_groups = Map.keys(exercises_by_group)

    logs = Notebook.list_workout_logs(user_id, date)

    {:ok,
     socket
     |> assign(user_id: user_id)
     |> assign(date: date)
     |> assign(exercises_by_group: exercises_by_group)
     |> assign(muscle_groups: muscle_groups)
     |> assign(selected_group: List.first(muscle_groups)) # Default to the first group
     |> assign(selected_exercise: nil)
     |> assign(logs: logs)
     |> assign(locale: locale)
     |> assign(form: to_form(%{"weight" => "", "reps" => ""}, as: :log))}
  end

  @impl true
  # Handle selecting a muscle group tab
  def handle_event("select_group", %{"group" => group}, socket) do
    {:noreply, assign(socket, selected_group: group, selected_exercise: nil)}
  end

  @impl true
  # Handle selecting a specific exercise to log
  def handle_event("select_exercise", %{"exercise" => exercise}, socket) do
    # Pre-populate weight and reps with the values of the last logged set of this exercise (if any)
    last_log =
      socket.assigns.logs
      |> Enum.filter(fn l -> l.exercise == exercise end)
      |> List.last()

    form_params =
      if last_log do
        %{
          "weight" => to_string(last_log.weight),
          "reps" => to_string(last_log.reps)
        }
      else
        %{"weight" => "", "reps" => ""}
      end

    {:noreply,
     socket
     |> assign(selected_exercise: exercise)
     |> assign(form: to_form(form_params, as: :log))}
  end

  @impl true
  # Reset the exercise selection and clear input form
  def handle_event("cancel_selection", _params, socket) do
    {:noreply,
     socket
     |> assign(selected_exercise: nil)
     |> assign(form: to_form(%{"weight" => "", "reps" => ""}, as: :log))}
  end

  @impl true
  # Save the logged set (weight and reps) for the selected exercise
  def handle_event("save_log", %{"log" => log_params}, socket) do
    user_id = socket.assigns.user_id
    date = socket.assigns.date
    exercise = socket.assigns.selected_exercise

    weight = log_params["weight"]
    reps = log_params["reps"]

    case Notebook.save_workout_log(user_id, date, exercise, weight, reps) do
      {:ok, log} ->
        logs = Notebook.list_workout_logs(user_id, date)
        form_params = %{
          "weight" => to_string(log.weight),
          "reps" => to_string(log.reps)
        }

        {:noreply,
         socket
         |> assign(logs: logs)
         |> assign(form: to_form(form_params, as: :log))
         |> put_flash(:info, gettext("Workout log saved!"))}

      {:error, changeset} ->
        {:noreply,
         socket
         |> assign(form: to_form(changeset))
         |> put_flash(:error, gettext("Failed to save log. Please check your inputs."))}
    end
  end

  @impl true
  # Delete a logged set by ID
  def handle_event("delete_log", %{"id" => log_id}, socket) do
    user_id = socket.assigns.user_id
    date = socket.assigns.date
    {:ok, _} = Notebook.delete_workout_log(user_id, String.to_integer(log_id))
    logs = Notebook.list_workout_logs(user_id, date)

    {:noreply,
     socket
     |> assign(logs: logs)
     |> put_flash(:info, gettext("Workout log deleted."))}
  end

  @impl true
  # Sync data in real-time when updates are broadcast via PubSub
  def handle_info({:workout_log_updated, date}, socket) do
    user_id = socket.assigns.user_id
    if Date.compare(date, socket.assigns.date) == :eq do
      logs = Notebook.list_workout_logs(user_id, date)
      {:noreply, assign(socket, logs: logs)}
    else
      {:noreply, socket}
    end
  end

  def handle_info(_other, socket) do
    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} active_tab="diary">
      <div class="max-w-4xl mx-auto space-y-6">

        <!-- Header Card -->
        <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4 bg-white dark:bg-zinc-900 p-6 rounded-3xl shadow-sm border border-slate-100 dark:border-zinc-850">
          <div class="space-y-1">
            <h1 class="text-2xl font-extrabold text-slate-800 dark:text-zinc-100 tracking-tight flex items-center gap-2">
            <img src={~p"/images/label.svg"} class="w-16 h-auto" alt="No data" />
              {gettext("Workout Logger")}
            </h1>
            <p class="text-sm font-semibold text-slate-500">
              {format_date(@date, @locale)}
            </p>
          </div>
          <div class="flex items-center gap-2">
            <.link
              navigate={~p"/"}
              class="flex items-center gap-2 px-5 py-2.5 bg-slate-100 hover:bg-slate-200 dark:bg-zinc-800 dark:hover:bg-zinc-700 dark:text-zinc-200 text-slate-700 font-bold rounded-2xl shadow-sm transition-all duration-200 cursor-pointer text-sm"
            >
              <.icon name="hero-arrow-left" class="size-4" /> {gettext("Back to Diary")}
            </.link>
          </div>
        </div>

        <div class="grid grid-cols-1 md:grid-cols-5 gap-8">

          <!-- Left Side: Selection of Muscle Group and Exercises (3 columns) -->
          <div class="md:col-span-3 space-y-6">
            <div class="bg-white dark:bg-zinc-900 rounded-3xl shadow-md border border-slate-100 dark:border-zinc-850 p-6 space-y-4">
              <h2 class="text-xs font-black text-slate-400 dark:text-zinc-500 uppercase tracking-widest">
                {gettext("Select Target Muscle")}
              </h2>
              <!-- Responsive grid to accommodate 7 muscle groups instead of 4 -->
              <div class="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-2 lg:grid-cols-3 gap-2.5">
                <%= for group <- @muscle_groups do %>
                  <.muscle_group_button
                    group={group}
                    active={@selected_group == group}
                  />
                <% end %>
              </div>
            </div>

            <!-- Exercises selector component -->
            <%= if @selected_group do %>
              <div class="bg-white dark:bg-zinc-900 rounded-3xl shadow-md border border-slate-100 dark:border-zinc-850 p-6 space-y-4">
                <h2 class="text-xs font-black text-slate-400 dark:text-zinc-500 uppercase tracking-widest">
                  {gettext("Select Exercise")} ({ Gettext.gettext(DiaryWeb.Gettext, @selected_group) })
                </h2>
                <!-- Scrollable container for exercises when the list is long -->
                <div class="space-y-2.5 max-h-[380px] overflow-y-auto pr-1">
                  <%= for exercise <- Map.get(@exercises_by_group, @selected_group, []) do %>
                    <.exercise_selection_row
                      exercise={exercise}
                      active={@selected_exercise == exercise}
                      logs={Enum.filter(@logs, fn l -> l.exercise == exercise end)}
                    />
                  <% end %>
                </div>
              </div>
            <% end %>
          </div>

          <!-- Right Side: Input Form and Today's Log (2 columns) -->
          <div class="md:col-span-2 space-y-6">
            <!-- Input Form Card -->
            <div class="bg-white dark:bg-zinc-900 rounded-3xl shadow-md border border-slate-100 dark:border-zinc-850 p-6 space-y-4">
              <h2 class="text-xs font-black text-slate-400 dark:text-zinc-500 uppercase tracking-widest">
                Log Set
              </h2>

              <%= if @selected_exercise do %>
                <!-- Translate exercise name dynamically using Gettext -->
                <p class="text-sm font-extrabold text-zinc-700 dark:text-zinc-300">{Gettext.gettext(DiaryWeb.Gettext, @selected_exercise)}</p>

                <.form for={@form} id="workout-log-form" phx-submit="save_log" novalidate class="space-y-4">
                  <div class="grid grid-cols-2 gap-4">
                    <div>
                      <.input
                        field={@form[:weight]}
                        type="number"
                        step="any"
                        min="0"
                        placeholder="0.0"
                        label={gettext("Weight (kg)")}
                        autocomplete="off"
                        id="workout-weight-input"
                        class="w-full px-4 py-3 text-slate-700 dark:text-zinc-200 bg-white dark:bg-zinc-900 border border-slate-200 dark:border-zinc-800 rounded-2xl focus:ring-2 focus:ring-zinc-800/10 focus:border-zinc-800 outline-none transition-all duration-200 shadow-sm"
                      />
                    </div>
                    <div>
                      <.input
                        field={@form[:reps]}
                        type="number"
                        min="1"
                        placeholder="0"
                        label={gettext("Reps")}
                        autocomplete="off"
                        id="workout-reps-input"
                        class="w-full px-4 py-3 text-slate-700 dark:text-zinc-200 bg-white dark:bg-zinc-900 border border-slate-200 dark:border-zinc-800 rounded-2xl focus:ring-2 focus:ring-zinc-800/10 focus:border-zinc-800 outline-none transition-all duration-200 shadow-sm"
                      />
                    </div>
                  </div>

                  <div class="flex items-center justify-end gap-2.5 pt-2">
                    <button
                      type="button"
                      phx-click="cancel_selection"
                      class="px-5 py-3 bg-slate-100 hover:bg-slate-200 dark:bg-zinc-800 dark:hover:bg-zinc-700 dark:text-zinc-300 text-slate-700 font-bold rounded-2xl transition-all duration-200 cursor-pointer text-xs"
                    >
                      {gettext("Cancel")}
                    </button>
                    <button
                      type="submit"
                      id="save-workout-btn"
                      class="px-6 py-3 bg-zinc-800 hover:bg-zinc-900 text-white font-extrabold rounded-2xl shadow-lg shadow-zinc-850/10 hover:shadow-zinc-850/20 transition-all duration-200 cursor-pointer text-xs"
                    >
                      {gettext("Save Entry")}
                    </button>
                  </div>
                </.form>
              <% else %>
                <div class="flex flex-col items-center justify-center py-10 text-slate-300 dark:text-zinc-700">
                  <img src={~p"/images/on_the_way.svg"} class="w-16 h-auto" alt="No data" />
                  <p class="text-xs font-bold text-slate-400 dark:text-zinc-500 mb-1">{gettext("No Exercise Selected")}</p>
                  <p class="text-[10px] text-slate-400 dark:text-zinc-500 text-center max-w-[200px]">
                    {gettext("Choose a muscle group and an exercise to start logging your workout.")}
                  </p>
                </div>
              <% end %>
            </div>

            <!-- List of logs for the date -->
            <div class="bg-white dark:bg-zinc-900 rounded-3xl shadow-md border border-slate-100 dark:border-zinc-850 p-6 space-y-4">
              <div class="flex items-center justify-between">
                <h2 class="text-xs font-black text-slate-400 dark:text-zinc-500 uppercase tracking-widest">
                  {gettext("Today's Workouts")}
                </h2>
                <span class="text-[10px] bg-zinc-100 dark:bg-zinc-800 text-zinc-700 dark:text-zinc-300 px-2 py-1 rounded-full font-bold">
                  {Enum.count(@logs)} {gettext("Sets")}
                </span>
              </div>

              <div class="space-y-2.5">
                <%= if Enum.empty?(@logs) do %>
                  <div class="flex flex-col items-center justify-center py-10 text-slate-300 dark:text-zinc-700">
                    <img src={~p"/images/hono.svg"} class="w-24 h-auto" alt="No data" />
                    <p class="text-xs font-bold text-slate-400 dark:text-zinc-500">{gettext("Only you can ignite your own destiny.")}</p>
                  </div>
                <% else %>
                  <%= for log <- @logs do %>
                    <.logged_workout_row log={log} />
                  <% end %>
                <% end %>
              </div>
            </div>
          </div>

        </div>
      </div>
    </Layouts.app>
    """
  end

  # Component for rendering muscle group buttons
  defp muscle_group_button(assigns) do
    ~H"""
    <button
      type="button"
      phx-click="select_group"
      phx-value-group={@group}
      class={[
        "flex items-center justify-center p-4 rounded-2xl border text-center font-black transition-all duration-200 cursor-pointer",
        @active && "bg-zinc-800 border-zinc-850 text-white shadow-lg shadow-zinc-850/10 scale-[1.02]",
        !@active && "bg-slate-50 border-slate-100 dark:bg-zinc-800/30 dark:border-zinc-800 hover:border-zinc-250 text-slate-700 dark:text-zinc-300 hover:bg-zinc-50/50"
      ]}
    >
      <span class="text-xs">{Gettext.gettext(DiaryWeb.Gettext, @group)}</span>
    </button>
    """
  end

  # Component for rendering exercise selection rows
  defp exercise_selection_row(assigns) do
    ~H"""
    <button
      type="button"
      phx-click="select_exercise"
      phx-value-exercise={@exercise}
      class={[
        "w-full flex items-center justify-between p-4 rounded-2xl border text-left font-extrabold transition-all duration-200 cursor-pointer",
        @active && "bg-zinc-50 dark:bg-zinc-800 border-zinc-350 dark:border-zinc-700 text-zinc-850 dark:text-zinc-100 shadow-sm",
        !@active && "bg-white dark:bg-zinc-900 border-slate-100 dark:border-zinc-850 hover:border-slate-200 dark:hover:border-zinc-750 text-slate-700 dark:text-zinc-300"
      ]}
    >
      <!-- Translate exercise name dynamically using Gettext -->
      <span class="text-xs">{Gettext.gettext(DiaryWeb.Gettext, @exercise)}</span>
      <div class="flex items-center gap-2">
        <%= if Enum.any?(@logs) do %>
          <span class="text-[10px] bg-zinc-100 dark:bg-zinc-800 text-zinc-700 dark:text-zinc-300 px-2 py-1 rounded-full font-bold">
            {Enum.count(@logs)} sets
          </span>
        <% else %>
          <span class="text-[10px] text-slate-400 dark:text-zinc-500 font-bold">Not logged</span>
        <% end %>
        <.icon name="hero-chevron-right" class="size-3.5 text-slate-400 dark:text-zinc-500" />
      </div>
    </button>
    """
  end

  # Component for rendering already logged workouts
  defp logged_workout_row(assigns) do
    ~H"""
    <div class="flex items-center justify-between p-3 bg-slate-50 dark:bg-zinc-800/40 rounded-2xl border border-slate-100 dark:border-zinc-850 hover:border-zinc-300 dark:hover:border-zinc-700 transition-all duration-200">
      <div class="space-y-1">
        <!-- Translate exercise name dynamically using Gettext -->
        <p class="text-xs font-black text-slate-700 dark:text-zinc-300">{Gettext.gettext(DiaryWeb.Gettext, @log.exercise)}</p>
        <p class="text-[10px] font-bold text-slate-400 dark:text-zinc-500">
          {@log.weight} kg × {@log.reps} reps
        </p>
      </div>
      <button
        type="button"
        phx-click="delete_log"
        phx-value-id={@log.id}
        class="p-1.5 text-slate-400 hover:text-rose-500 hover:bg-rose-50 dark:hover:bg-rose-950/30 rounded-xl transition-all duration-200 cursor-pointer"
      >
        <.icon name="hero-trash" class="size-4" />
      </button>
    </div>
    """
  end

  # Format target date based on selected locale
  defp format_date(date, locale) do
    case locale do
      "ja" ->
        "#{date.year}年 #{date.month}月#{date.day}日"

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

        "#{month_name} #{date.day}, #{date.year}"
    end
  end
end
