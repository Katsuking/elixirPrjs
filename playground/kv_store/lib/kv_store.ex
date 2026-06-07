defmodule KvStore do
  use GenServer

  @doc """
  Key-Valueストアのプロセスを起動します。
  """
  def start_link(_opts \\ []) do
    # GenServer.start_link(モジュール名, 初期状態, オプション)
    # ここでは初期状態として空のマップ %{} を渡しています。
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  @doc """
  値を保存します。
  """
  def put(key, value) do
    # castは「投げっぱなし（非同期）」。返り値を待たずに即座に終了します。
    GenServer.cast(__MODULE__, {:put, key, value})
  end

  @doc """
  値を取得します。見つからない場合は nil を返します。
  """
  def get(key) do
    # callは「返り値を待つ（同期）」。サーバーからの応答を待ちます。
    GenServer.call(__MODULE__, {:get, key})
  end

  # --- サーバーコールバック（内部で非同期に実行される処理） ---

  # start_linkから呼ばれ、プロセスの初期状態（空のマップ）を確定させます。
  # init はお作法で決まった関数名
  # 呼び出すきっかけ: GenServer.start_link/3
  @impl true # これは親（GenServer）で決められたコールバック関数を今から実装します
  def init(initial_state) do
    {:ok, initial_state}
  end

  # get（call）が呼ばれた時の内部処理
  # 呼び出すきっかけ: GenServer.call/3 同期処理
  @impl true
  def handle_call({:get, key}, _from, current_state) do
    # Map.getで現在の状態（マップ）から値を取り出します
    reply = Map.get(current_state, key)
    # {:reply, 返り値, 次の状態} を返す決まりになっています（状態は変更しない）
    {:reply, reply, current_state}
  end

  # put（cast）が呼ばれた時の内部処理
  # 呼び出すきっかけ: GenServer.cast/2 非同期処理
  @impl true
  def handle_cast({:put, key, value}, current_state) do
    # Map.putで、現在の状態（マップ）に新しいキーと値を追加した「新しいマップ」を作ります
    new_state = Map.put(current_state, key, value)
    # {:noreply, 次の状態} を返す決まりになっています
    {:noreply, new_state}
  end
end
