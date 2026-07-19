defmodule DiaryWeb.Components.Diary.SaveButtonComponent do
  use Phoenix.Component

  # Gradient styled button that triggers a `set_mood` event.
  # The button sends the *status_to_save* (the mood that should be persisted)
  # via the `phx-value-status` attribute.
  attr :status_to_save, :string, required: true, doc: "Mood status to send on click"
  # LiveView event name; defaults to "set_mood".
  attr :on_set, :string, default: "set_mood", doc: "Event name for callback"

  def save_mood_button(assigns) do
    ~H"""
    <button phx-click={@on_set}
            phx-value-status={@status_to_save}
            class="px-4 py-2 bg-gradient-to-r from-indigo-500 to-pink-500 text-white rounded-md hover:from-indigo-600 hover:to-pink-600 transition">
      Save Mood
    </button>
    """
  end

end
