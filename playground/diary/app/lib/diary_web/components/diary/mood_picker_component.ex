defmodule DiaryWeb.Components.Diary.MoodPickerComponent do
  use DiaryWeb, :html

  # Currently selected mood status
  attr :selected, :string, default: nil, doc: "Currently selected mood status"
  # Event name to trigger when a mood is selected
  attr :on_set, :string, default: "set_mood", doc: "LiveView event name"

  def mood_picker(assigns) do
    ~H"""
    <div class="mood-picker">
      <button phx-click={@on_set}
              phx-value-status="good"
              class={"emoji-btn inline-flex items-center gap-2 " <> (if @selected == "good", do: "border-2 border-amber-500 ", else: "") <> "text-black"}
              aria-pressed={@selected == "good"}>
        <%= gettext("Good") %>
        <img src={~p"/images/good.svg"} class="w-6 h-6" alt="good"/>
      </button>

      <button phx-click={@on_set}
              phx-value-status="very good"
              class={"emoji-btn inline-flex items-center gap-2 " <> (if @selected == "very good", do: "border-2 border-amber-500 ", else: "") <> "text-black"}
              aria-pressed={@selected == "very good"}>
        <%= gettext("Very good") %>
        <img src={~p"/images/very_good.svg"} class="w-6 h-6" alt="very_good"/>
      </button>

      <button phx-click={@on_set}
              phx-value-status="beast"
              class={"emoji-btn inline-flex items-center gap-2 " <> (if @selected == "beast", do: "border-2 border-amber-500 ", else: "") <> "text-black"}
              aria-pressed={@selected == "beast"}>
        <%= gettext("Beast") %>
        <img src={~p"/images/beast.svg"} class="w-6 h-6" alt="beast"/>
      </button>

      <button phx-click={@on_set}
              phx-value-status="on_fire"
              class={"emoji-btn inline-flex items-center gap-2 " <> (if @selected == "on_fire", do: "border-2 border-amber-500 ", else: "") <> "text-black"}
              aria-pressed={@selected == "on_fire"}>
        <%= gettext("On fire") %>
        <img src={~p"/images/on_fire.svg"} class="w-6 h-6" alt="on_fire"/>

      </button>

      <button phx-click={@on_set}
              phx-value-status="disciplined"
              class={"emoji-btn inline-flex items-center gap-2 " <> (if @selected == "disciplined", do: "border-2 border-amber-500 ", else: "") <> "text-black"}
              aria-pressed={@selected == "disciplined"}>
        <%= gettext("Disciplined") %>
        <img src={~p"/images/disciplined.svg"} class="w-6 h-6" alt="disciplined"/>
      </button>
    </div>
    """
  end
end
