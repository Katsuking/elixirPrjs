defmodule HelloLiveviewWeb.Components.SampleComponent do
  use HelloLiveviewWeb, :live_component

  def update(assigns, socket) do
    {:ok, socket
      |> assign(:score, assigns[:score] || 0) # # 初回は assigns に何も入っていない可能性を考慮してデフォルト値を設定
      |> assign(assigns)
    }
  end

  def render(assigns) do
    ~H"""
    <div id={@id}>
      <h3>Sample component (ID:{@id})</h3>
      <p>score: {@score}</p>
    </div>
    """
  end
end
