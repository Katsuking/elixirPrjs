defmodule HelloLiveviewWeb.CounterLive2 do
  use HelloLiveviewWeb, :live_view

  # 1. 初期状態の設定 (mount)
  @spec mount(any(), any(), map()) :: {:ok, map()}
  def mount(_params, _session, socket) do
    # {:ok, assign(socket, [count: 0, val: 1])}
    # formの場合はまとめて、formで渡すのがphoenix流
    form = create_form(%{"number_input" => 1})
    {:ok, assign(socket, count: 0, form: form, history: [])}
  end

  @form_schema %{number_input: :integer}

  @doc """
  formの入力値に対して、バリデーションを かける
  """
  defp create_form(params) do
    {%{}, @form_schema}
    |> Ecto.Changeset.cast(params, [:number_input])
    |> Ecto.Changeset.validate_required([:number_input])
    |> to_form(as: :form_sample)
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
      <%!-- 1. フラッシュメッセージを表示するエリアを追加 --%>
    <p class="text-blue-600 font-bold"><%= Phoenix.Flash.get(@flash, :info) %></p>
    <p class="text-red-600 font-bold"><%= Phoenix.Flash.get(@flash, :error) %></p>
    </div>
    """
  end

  # 3. イベントの処理 (handle_event)
  def handle_event("increment", _params, socket) do
    {:noreply, update(socket, :count, &(&1 + 1))}
  end

  def handle_event("validate", %{"form_sample" => %{"number_input" => val}}, socket) do
    {:noreply, assign(socket, form: create_form(%{number_input: val}))}
  end

  def handle_event("add",   %{"form_sample" => %{"number_input" => val}}, socket) do
    Process.send_after(self(), :clear_flash, 3000) # 3秒後（3000ミリ秒後）に、自分自身(self())に :clear_flash というメッセージを送る予約
    case Integer.parse(val) do
      {input_num, _} ->
        {:noreply, socket
          |> update(:count, &(&1 + input_num))
          |> put_flash(:info, "#{input_num} を足しました！") # たったこれだけでフラッシュメッセージを出せる
          |> update(:history, fn h -> [input_num | h] end)
          |> assign(form: create_form(%{number_input: 0}))
        }
        :error -> {:noreply, socket}
    end
  end

  @doc """
  Process.send_after(self(), :clear_flash, 3000) で3秒後に実行される処理
  """
  def handle_info(:clear_flash, socket) do
    # ここで実際に「消去」の処理を指示している
    {:noreply, clear_flash(socket)}
end

end
