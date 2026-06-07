```mermaid
sequenceDiagram
    autonumber
    actor Client as クライアント (例: IExの画面)
    participant KV as KvStoreプロセス (GenServer)
    Note over Client, KV: ■ 1. 起動フェーズ (start_link)
    Client->>KV: KvStore.start_link() を呼び出す
    Note over KV: GenServer.start_link が新しいプロセスを起動
    rect rgb(240, 240, 255)
        Note over KV: [コールバック] init(%{}) が実行され<br/>初期状態（空のマップ）を確定
    end
    KV-->>Client: {:ok, pid} (起動完了の応答)
    Note over Client, KV: ■ 2. 値の保存フェーズ (put / cast: 非同期)
    Client->>KV: KvStore.put("key1", "value1") を呼び出す
    Note over Client: GenServer.cast は非同期のため、<br/>サーバーの返事を待たずに即座に戻る
    rect rgb(255, 240, 240)
        Note over KV: [コールバック] handle_cast({:put, "key1", "value1"}, current_state) が実行される
        Note over KV: 状態を %{"key1" => "value1"} に更新
    end
    Note over Client, KV: ■ 3. 値の取得フェーズ (get / call: 同期)
    Client->>KV: KvStore.get("key1") を呼び出す
    Note over Client: GenServer.call は同期のため、<br/>サーバーから結果が返るまで待機（ブロック）する
    rect rgb(240, 255, 240)
        Note over KV: [コールバック] handle_call({:get, "key1"}, from, current_state) が実行される
        Note over KV: マップから "value1" を取り出す
        KV-->>Client: "value1" を返す
    end
    Note over Client: "value1" を受け取り、次の処理へ進む
```

## 動作確認の手順と流れ

以下は、`iex -S mix` を使って実際にこの `KvStore` を起動し、動作確認を行う際の流れを示す図です。

```mermaid
sequenceDiagram
    autonumber
    actor User as 開発者 (あなた)
    participant IEx as IExシェル (ターミナル)
    participant KV as KvStoreプロセス

    Note over User, IEx: ■ 1. IExの起動
    User->>IEx: iex -S mix を実行する
    IEx-->>User: プロジェクトがコンパイルされ起動する

    Note over User, KV: ■ 2. プロセスの起動
    User->>IEx: KvStore.start_link() を入力
    IEx->>KV: プロセスを名前付き (__MODULE__) で起動
    KV-->>IEx: {:ok, #PID<...>}
    IEx-->>User: {:ok, #PID<...>} (起動成功)

    Note over User, KV: ■ 3. データの保存 (put)
    User->>IEx: KvStore.put("apple", 150) を入力
    IEx->>KV: データの書き込み (cast) を要求
    KV-->>IEx: (非同期のため即座に制御を戻す)
    IEx-->>User: :ok

    Note over User, KV: ■ 4. データの取得 (get)
    User->>IEx: KvStore.get("apple") を入力
    IEx->>KV: データの読み込み (call) を要求
    Note over KV: 状態のマップから "apple" に対応する 150 を取得
    KV-->>IEx: 150 (同期で返答)
    IEx-->>User: 150 (結果が表示される)
```

### 動作確認コードの例

実際にターミナルやIEx上で入力するコマンドの例です。

```elixir
# 1. ターミナルでプロジェクトを読み込んでIExを起動します
# iex -S mix

# 2. KvStoreプロセスを起動します（すでに自動起動する設定になっている場合は不要です）
KvStore.start_link()

# 3. "apple" というキーに 150 という値を保存します
KvStore.put("apple", 150)

# 4. "apple" というキーの値を取得します
KvStore.get("apple")
# => 150 が返ってくれば動作確認完了です！
```
