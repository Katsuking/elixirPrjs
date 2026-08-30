defmodule DiaryWeb.Diary.DiaryComponent do
  @moduledoc """
  LiveComponent that encapsulates the diary bullet points list and the add new entry form.
  It handles validation, creation, deletion, and real-time streaming of diary items.
  """
  use DiaryWeb, :live_component
  use Gettext, backend: DiaryWeb.Gettext

  alias Diary.Notebook
  alias Diary.DiaryItem

  @impl true
  def mount(socket) do
    # Initialize the character counter
    {:ok, assign(socket, content_length: 0)}
  end

  @impl true
  def update(assigns, socket) do
    cond do
      # Handle real-time creation from PubSub forwarded by parent LiveView
      Map.has_key?(assigns, :diary_item_created) ->
        created_item = assigns.diary_item_created
        socket =
          if created_item.date == socket.assigns.date do
            stream_insert(socket, :diary_items, created_item)
          else
            socket
          end

        {:ok, socket}

      # Handle real-time deletion from PubSub forwarded by parent LiveView
      Map.has_key?(assigns, :diary_item_deleted) ->
        deleted_item = assigns.diary_item_deleted
        {:ok, stream_delete(socket, :diary_items, deleted_item)}

      # Normal initialization or parameter changes
      true ->
        user_id = assigns.user_id
        date = assigns.date
        locale = assigns.locale || "en"
        Gettext.put_locale(DiaryWeb.Gettext, locale)

        diary_items = Notebook.list_diary_items(user_id, date)
        changeset = Notebook.change_diary_item(%DiaryItem{date: date})

        {:ok,
         socket
         |> assign(user_id: user_id)
         |> assign(date: date)
         |> assign(locale: locale)
         |> assign(content_length: 0)
         |> assign(form: to_form(changeset))
         |> stream(:diary_items, diary_items, reset: true)}
    end
  end

  @impl true
  def handle_event("validate", %{"diary_item" => %{"content" => content}}, socket) do
    # Validate the diary item content length reactively
    changeset =
      %DiaryItem{date: socket.assigns.date}
      |> Notebook.change_diary_item(%{"content" => content})
      |> Map.put(:action, :validate)

    {:noreply,
     socket
     |> assign(form: to_form(changeset))
     |> assign(content_length: String.length(content))}
  end

  @impl true
  def handle_event("save", %{"diary_item" => %{"content" => content}}, socket) do
    user_id = socket.assigns.user_id
    date = socket.assigns.date

    # Create the diary item via Notebook context
    case Notebook.create_diary_item(user_id, %{"date" => date, "content" => content}) do
      {:ok, diary_item} ->
        # Clear the input field on successful save
        changeset = Notebook.change_diary_item(%DiaryItem{date: date})

        {:noreply,
         socket
         |> stream_insert(:diary_items, diary_item)
         |> assign(form: to_form(changeset))
         |> assign(content_length: 0)
         |> put_flash(:info, gettext("Successfully added!"))}

      {:error, changeset} ->
        # Return form with errors
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    user_id = socket.assigns.user_id
    diary_item = Notebook.get_diary_item!(user_id, id)

    # Delete the diary item via Notebook context
    case Notebook.delete_diary_item(diary_item) do
      {:ok, deleted_item} ->
        {:noreply,
         socket
         |> stream_delete(:diary_items, deleted_item)
         |> put_flash(:info, gettext("Deleted!"))}

      {:error, _changeset} ->
        {:noreply,
         socket
         |> put_flash(:error, gettext("Failed to delete item."))}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <!-- Diary Bullet Points List -->
      <div class="p-8">
        <h2 class="text-xs font-bold text-slate-400 dark:text-zinc-400 uppercase tracking-widest mb-4">
          {gettext("Today's Entries")}
        </h2>

        <!-- Scrollable container for the list of entries -->
        <div class="max-h-[320px] overflow-y-auto pr-1">
          <div id="diary-items" phx-update="stream" class="space-y-2 min-h-[160px]">
            <!-- Empty State -->
            <div id="diary-empty-state" class="hidden only:flex flex-col items-center justify-center py-10 text-slate-300 dark:text-zinc-700">
              <img src={~p"/images/nodata.svg"} class="w-32 h-auto mb-3" alt="No data" />
              <p class="text-sm font-medium text-slate-400 dark:text-zinc-400">
                {gettext("Record even the small things you’ve accomplished, and use them to check that you’re maintaining a disciplined lifestyle.")}
              </p>
            </div>

            <!-- List entries -->
            <div
              :for={{id, item} <- @streams.diary_items}
              id={id}
              class="group flex items-center justify-between px-4 bg-slate-50/60 hover:bg-zinc-50/50 dark:bg-zinc-800/40 dark:hover:bg-zinc-800/80 border border-slate-100 dark:border-zinc-850 hover:border-zinc-300 dark:hover:border-zinc-700 rounded-xl transition-all duration-200"
            >
              <div class="flex items-start gap-1 pr-4">
                <span class="flex-shrink-0 text-lg select-none text-zinc-500 group-hover:scale-110 transition-transform duration-200">•</span>
                <p class="text-slate-700 dark:text-zinc-300 font-medium break-all leading-relaxed">{item.content}</p>
              </div>

              <div class="flex items-center gap-1 opacity-100 md:opacity-0 md:group-hover:opacity-100 transition-opacity duration-200 flex-shrink-0">
                <button
                  type="button"
                  phx-click="delete"
                  phx-value-id={item.id}
                  phx-target={@myself}
                  id={"delete-item-#{item.id}"}
                  class="p-1.5 text-slate-400 hover:text-rose-500 rounded-lg hover:bg-rose-50 dark:hover:bg-rose-950/30 transition-all duration-200 cursor-pointer"
                  title={gettext("Delete item")}
                >
                  <.icon name="hero-trash" class="size-4" />
                </button>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- Add Entry Form Area -->
      <div class="p-8 bg-slate-50/80 dark:bg-zinc-800/20 border-t border-slate-100 dark:border-zinc-800">
        <h2 class="text-xs font-bold text-slate-400 dark:text-zinc-400 uppercase tracking-widest mb-4">
          {gettext("Add New Entry")}
        </h2>

        <.form for={@form} id="new-diary-item-form" phx-change="validate" phx-submit="save" phx-target={@myself} class="space-y-4">
          <div class="relative">
            <.input
              field={@form[:content]}
              type="text"
              placeholder={gettext("What did you do today?")}
              autocomplete="off"
              id="diary-item-content-input"
              class="w-full pl-4 pr-20 py-3.5 text-slate-700 dark:text-zinc-50 bg-white dark:bg-zinc-900 border border-slate-200 dark:border-zinc-800 rounded-2xl focus:ring-2 focus:ring-zinc-800/10 focus:border-zinc-800 outline-none transition-all duration-200 placeholder:text-slate-400 dark:placeholder:text-zinc-600 shadow-sm"
              error_class="border-rose-500 focus:ring-rose-500/20 focus:border-rose-500"
            />

            <!-- Length character counter overlay -->
            <div class={[
              "absolute right-3.5 top-3.5 text-xs font-bold px-2 py-1 rounded-lg select-none pointer-events-none transition-colors duration-200",
              @content_length > 50 && "text-rose-600 bg-rose-50 dark:bg-rose-950/20",
              @content_length in 41..50 && "text-amber-600 bg-amber-50 dark:bg-amber-950/20",
              @content_length <= 40 && "text-slate-400 dark:text-zinc-400 bg-slate-100 dark:bg-zinc-800"
            ]}>
              {@content_length}/50
            </div>
          </div>

          <div class="flex items-center justify-end">
            <button
              type="submit"
              id="submit-item-btn"
              disabled={@content_length == 0 or @content_length > 50}
              class="flex items-center gap-2 px-6 py-3 bg-zinc-800 hover:bg-zinc-900 disabled:bg-slate-200 dark:disabled:bg-zinc-800 text-white disabled:text-slate-400 dark:disabled:text-zinc-600 font-bold rounded-2xl shadow-lg shadow-zinc-850/10 hover:shadow-zinc-850/20 disabled:shadow-none transition-all duration-200 transform active:scale-[0.98] disabled:transform-none cursor-pointer disabled:cursor-not-allowed"
            >
              <.icon name="hero-plus" class="size-4" /> {gettext("Add Bullet")}
            </button>
          </div>
        </.form>
      </div>
    </div>
    """
  end
end
