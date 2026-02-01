defmodule HelloLiveviewWeb.CounterLive2 do
  use HelloLiveviewWeb, :live_view

  # 1. 初期状態の設定 (mount)
  @spec mount(any(), any(), map()) :: {:ok, map()}
  def mount(_params, _session, socket) do
    # {:ok, assign(socket, [count: 0, val: 1])}
    # formの場合はまとめて、formで渡すのがphoenix流
    form = to_form(%{"number_input" => 1})
    {:ok, assign(socket, count: 0, form: form, history: [])}
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
        <.input type="number" field={@form[:number_input]} label="加算する数字を入力" />
        <button class="bg-green-500 text-white px-4 py-2 rounded ml-2">
        加算する
      </button>
      </form>
      <div>
        <%= if @history == [] do %>
          <p>履歴はまだありません</p>
        <% else %>
          <li :for={val <- @history} class="p-2 rounded border-l-4 border-green-500">
              <span class="text-sm">加算成功:</span>
              <span class="font-mono font-bold ml-2">+<%= val %></span>
          </li>
        <% end %>
      </div>
    </div>
    """
  end

  # 3. イベントの処理 (handle_event)
  def handle_event("increment", _params, socket) do
    {:noreply, update(socket, :count, &(&1 + 1))}
  end

  def handle_event("validate", %{"number_input" => val}, socket) do
    {:noreply, assign(socket, form: to_form(%{"number_input" => val}))}
  end

  def handle_event("add", %{"number_input" => val}, socket) do
    # 重要：val は文字列なので String.to_integer で数値に変換する
    input_num = String.to_integer(val)
    {:noreply,
      socket
      |> update(:count, &(&1 + input_num)) # update(socket, :count, fn current_value -> current_value + input_num end)
      |> update(:history, fn h -> [ input_num | h ] end)
      |> assign(form: to_form(%{"number_input" => 0})) # 送信後は0に戻す例
    }
  end

end
