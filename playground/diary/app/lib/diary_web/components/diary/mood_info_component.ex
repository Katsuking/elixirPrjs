defmodule DiaryWeb.Components.Diary.MoodInfoComponent do
  use Phoenix.Component

  attr :mood, :any, default: nil, doc: "mood or nil"

  def mood_info(assigns) do
    ~H"""
    <div class="text-center text-white">
      <%= if @mood do %>
      <p class="mb-4">Mood: <%= @mood.status %></p>
      <% else %>
      <p class="mb-4">No mood redcorded yet.</p>
      <% end %>
    </div>
    """
  end
end
