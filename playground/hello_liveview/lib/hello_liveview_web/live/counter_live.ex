defmodule HelloLiveviewWeb.CounterLive do
  use HelloLiveviewWeb, :live_view
  import HelloLiveviewWeb.CoreComponents

  alias HelloLiveviewWeb.Components.SampleComponent

  # 1. 初期状態の設定 (mount)
  @spec mount(any(), any(), map()) :: {:ok, map()}
  def mount(_params, _session, socket) do
    {:ok, assign(socket, [count: 0, val: 1])}
  end

  # 2. 画面の表示 (render)
  # ~H は HEEx（HTML + Embedded Elixir）というテンプレート形式です
  def render(assigns) do
    ~H"""
    <div class="p-10 text-center">
      <h1 class="text-4xl font-bold">現在のカウント: <%= @count %></h1>
      <.button phx-click="increment" class="mt-4 bg-blue-500 text-white px-4 py-2 rounded">
        増やす (+1)
      </.button>

      <form phx-submit="add" phx-change="validate" class="mt-8" novalidate>
        <%!-- <input type="number" name="number_input" value={@val} /> --%>
        <.input type="number" name="number_input" value={@val} label="加算する数字を入力" errors={[]} />
        <button class="bg-green-500 text-white px-4 py-2 rounded ml-2">
        加算する
      </button>
      </form>

      <div>
        <.live_component module={SampleComponent} id="test-sample" score={@count} />
      </div>
    </div>
    """
  end

  # 3. イベントの処理 (handle_event)
  def handle_event("increment", _params, socket) do
    {:noreply, update(socket, :count, &(&1 + 1))}
  end

  def handle_event("validate", %{"number_input" => val}, socket) do
    new_val = case Integer.parse(val) do
      {num, _} -> num
      :error ->+ 0
    end
    {:noreply, assign(socket, :val, new_val)}
  end

  def handle_event("add", _params, socket) do
    new_count = socket.assigns.count + socket.assigns.val
    {:noreply, assign(socket, :count, new_count)}
  end
end
