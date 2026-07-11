defmodule DiaryWeb.DiaryLive do
  @moduledoc """
  LiveView for managing and displaying bullet diary items.
  """
  use DiaryWeb, :live_view

  alias Diary.Notebook
  alias Diary.DiaryItem

  @impl true
  def mount(_params, _session, socket) do
    # Get today's date
    date = Date.utc_today()

    # List items for today
    diary_items = Notebook.list_diary_items(date)

    # Prepare an empty changeset for the form
    changeset = Notebook.change_diary_item(%DiaryItem{date: date})

    {:ok,
     socket
     |> assign(date: date)
     |> assign(content_length: 0)
     # Assign form derived from changeset
     |> assign(form: to_form(changeset))
     # Initialize the live stream of diary items
     |> stream(:diary_items, diary_items)}
  end

  @impl true
  # Handle changing date from date picker input
  def handle_event("change_date", %{"date" => date_str}, socket) do
    date = Date.from_iso8601!(date_str)
    diary_items = Notebook.list_diary_items(date)
    changeset = Notebook.change_diary_item(%DiaryItem{date: date})

    {:noreply,
     socket
     |> assign(date: date)
     |> assign(content_length: 0)
     |> assign(form: to_form(changeset))
     # Reset stream with new items
     |> stream(:diary_items, diary_items, reset: true)}
  end

  # Handle adjusting date via back/forward buttons
  def handle_event("adjust_date", %{"days" => days_str}, socket) do
    days = String.to_integer(days_str)
    date = Date.add(socket.assigns.date, days)
    diary_items = Notebook.list_diary_items(date)
    changeset = Notebook.change_diary_item(%DiaryItem{date: date})

    {:noreply,
     socket
     |> assign(date: date)
     |> assign(content_length: 0)
     |> assign(form: to_form(changeset))
     # Reset stream with new items
     |> stream(:diary_items, diary_items, reset: true)}
  end

  # Handle inline form validation to track characters count and errors
  def handle_event("validate", %{"diary_item" => %{"content" => content}}, socket) do
    changeset =
      %DiaryItem{date: socket.assigns.date}
      |> Notebook.change_diary_item(%{"content" => content})
      |> Map.put(:action, :validate)

    {:noreply,
     socket
     |> assign(form: to_form(changeset))
     |> assign(content_length: String.length(content))}
  end

  # Handle saving new diary item
  def handle_event("save", %{"diary_item" => %{"content" => content}}, socket) do
    case Notebook.create_diary_item(%{"date" => socket.assigns.date, "content" => content}) do
      {:ok, diary_item} ->
        # Clear input on success
        changeset = Notebook.change_diary_item(%DiaryItem{date: socket.assigns.date})

        {:noreply,
         socket
         |> stream_insert(:diary_items, diary_item)
         |> assign(form: to_form(changeset))
         |> assign(content_length: 0)
         |> put_flash(:info, "Successfully added!")}

      {:error, changeset} ->
        # Display validation errors
        {:noreply,
         socket
         |> assign(form: to_form(changeset))}
    end
  end

  # Handle deletion of a diary item
  def handle_event("delete", %{"id" => id}, socket) do
    diary_item = Notebook.get_diary_item!(id)

    case Notebook.delete_diary_item(diary_item) do
      {:ok, deleted_item} ->
        {:noreply,
         socket
         |> stream_delete(:diary_items, deleted_item)
         |> put_flash(:info, "Deleted!")}

      {:error, _changeset} ->
        {:noreply,
         socket
         |> put_flash(:error, "Failed to delete item.")}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <div class="bg-slate-50 min-h-screen py-12 px-4 sm:px-6 lg:px-8">
        <div class="max-w-2xl mx-auto">
          <!-- Main Card Container -->
          <div class="bg-white rounded-3xl shadow-xl border border-slate-100 overflow-hidden transition-all duration-300">

            <!-- Card Header with App Title and Navigation -->
            <div class="p-8 border-b border-slate-100 bg-gradient-to-r from-slate-50 to-white">
              <div class="flex items-center justify-between">
                <h1 class="text-3xl font-extrabold text-slate-800 tracking-tight flex items-center gap-3">
                  <span class="text-4xl">📔</span> Bullet Diary
                </h1>
                <div class="text-sm font-semibold text-slate-500 bg-slate-100 py-1.5 px-3.5 rounded-full shadow-inner">
                  50 chars max
                </div>
              </div>

              <!-- Date Navigator -->
              <div class="mt-6 flex items-center justify-between gap-4">
                <!-- Previous Day Button -->
                <button
                  type="button"
                  phx-click="adjust_date"
                  phx-value-days="-1"
                  id="prev-date-btn"
                  class="flex items-center justify-center p-2.5 rounded-xl border border-slate-200 text-slate-600 hover:text-indigo-600 hover:border-indigo-200 hover:bg-indigo-50/55 transition-all duration-200 cursor-pointer"
                >
                  <.icon name="hero-chevron-left" class="size-5" />
                </button>

                <!-- Date Picker -->
                <form phx-change="change_date" id="date-select-form" class="flex-grow">
                  <input
                    type="date"
                    name="date"
                    value={Date.to_iso8601(@date)}
                    id="date-picker-input"
                    class="w-full text-center font-bold text-slate-700 bg-white border border-slate-200 rounded-xl py-2 px-4 focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 outline-none transition-all duration-200 cursor-pointer"
                  />
                </form>

                <!-- Next Day Button -->
                <button
                  type="button"
                  phx-click="adjust_date"
                  phx-value-days="1"
                  id="next-date-btn"
                  class="flex items-center justify-center p-2.5 rounded-xl border border-slate-200 text-slate-600 hover:text-indigo-600 hover:border-indigo-200 hover:bg-indigo-50/55 transition-all duration-200 cursor-pointer"
                >
                  <.icon name="hero-chevron-right" class="size-5" />
                </button>
              </div>
            </div>

            <!-- Diary Bullet Points List -->
            <div class="p-8">
              <h2 class="text-xs font-bold text-slate-400 uppercase tracking-widest mb-4">
                Today's Entries
              </h2>

              <div id="diary-items" phx-update="stream" class="space-y-3.5 min-h-[160px]">
                <!-- Empty State -->
                <div class="hidden only:flex flex-col items-center justify-center py-10 text-slate-300">
                  <span class="text-5xl mb-3">🍃</span>
                  <p class="text-sm font-medium text-slate-400">No entries for this day. Add one below!</p>
                </div>

                <!-- Stream Item Row -->
                <div
                  :for={{id, item} <- @streams.diary_items}
                  id={id}
                  class="group flex items-center justify-between p-4 bg-slate-50/60 hover:bg-indigo-50/30 border border-slate-100 hover:border-indigo-100 rounded-2xl transition-all duration-200"
                >
                  <div class="flex items-start gap-3.5 pr-4">
                    <span class="flex-shrink-0 text-lg select-none text-indigo-500 group-hover:scale-110 transition-transform duration-200">•</span>
                    <p class="text-slate-700 font-medium break-all leading-relaxed">{item.content}</p>
                  </div>

                  <!-- Actions (Delete button) -->
                  <div class="flex items-center gap-1 opacity-0 group-hover:opacity-100 transition-opacity duration-200">
                    <button
                      type="button"
                      phx-click="delete"
                      phx-value-id={item.id}
                      id={"delete-item-#{item.id}"}
                      class="p-1.5 text-slate-400 hover:text-rose-500 rounded-lg hover:bg-rose-50 transition-all duration-200 cursor-pointer"
                      title="Delete item"
                    >
                      <.icon name="hero-trash" class="size-4" />
                    </button>
                  </div>
                </div>
              </div>
            </div>

            <!-- Add Entry Form Area -->
            <div class="p-8 bg-slate-50/80 border-t border-slate-100">
              <h2 class="text-xs font-bold text-slate-400 uppercase tracking-widest mb-4">
                Add New Entry
              </h2>

              <.form for={@form} id="new-diary-item-form" phx-change="validate" phx-submit="save" class="space-y-4">
                <div class="relative">
                  <!-- Custom styles on core components to override daisyUI defaults -->
                  <.input
                    field={@form[:content]}
                    type="text"
                    placeholder="What did you do today?"
                    autocomplete="off"
                    id="diary-item-content-input"
                    class="w-full pl-4 pr-20 py-3.5 text-slate-700 bg-white border border-slate-200 rounded-2xl focus:ring-2 focus:ring-indigo-500/20 focus:border-indigo-500 outline-none transition-all duration-200 placeholder:text-slate-400 shadow-sm"
                    error_class="border-rose-500 focus:ring-rose-500/20 focus:border-rose-500"
                  />

                  <!-- Length character counter overlay -->
                  <div class={[
                    "absolute right-3.5 top-3.5 text-xs font-bold px-2 py-1 rounded-lg select-none pointer-events-none transition-colors duration-200",
                    @content_length > 50 && "text-rose-600 bg-rose-50",
                    @content_length in 41..50 && "text-amber-600 bg-amber-50",
                    @content_length <= 40 && "text-slate-400 bg-slate-100"
                  ]}>
                    {@content_length}/50
                  </div>
                </div>

                <div class="flex items-center justify-end">
                  <button
                    type="submit"
                    id="submit-item-btn"
                    disabled={@content_length == 0 or @content_length > 50}
                    class="flex items-center gap-2 px-6 py-3 bg-indigo-600 hover:bg-indigo-700 disabled:bg-slate-200 text-white disabled:text-slate-400 font-bold rounded-2xl shadow-lg shadow-indigo-600/10 hover:shadow-indigo-600/20 disabled:shadow-none transition-all duration-200 transform active:scale-[0.98] disabled:transform-none cursor-pointer disabled:cursor-not-allowed"
                  >
                    <.icon name="hero-plus" class="size-4" /> Add Bullet
                  </button>
                </div>
              </.form>
            </div>

          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end
end
