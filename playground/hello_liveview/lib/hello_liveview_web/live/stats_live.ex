defmodule HelloLiveviewWeb.StatsLive do
  use HelloLiveviewWeb, :live_view
  alias HelloLiveviewWeb.Presence

  @topic "viewer_stats"

  def mount(_params, _session, socket) do
    if connected?(socket) do
      {:ok, _} = Presence.track(self(), @topic, socket.id, %{}) # 自身を閲覧者に追加
      Phoenix.PubSub.subscribe(HelloLiveview.PubSub, @topic) # 人数変化購読
    end
    {:ok, assign(socket, online_count: get_count())}
  end

  defp get_count do
    Presence.list(@topic)
      |> Map.keys()
      |> Enum.count()
  end

  def handle_info(%{event: "presence_diff"}, socket) do
    {:noreply, assign(socket, online_count: get_count())}
  end

  def render(assigns) do
    ~H"""
    <div class="p-5 border rounded-lg shadow-sm bg-white">
      <div class="flex items-center space-x-2">
        <div class="w-3 h-3 bg-green-500 rounded-full animate-pulse"></div>
        <span class="text-lg font-semibold text-gray-700">
          現在のオンラインユーザー: <%= @online_count %> 名
        </span>
      </div>
    </div>
    """
  end

end
