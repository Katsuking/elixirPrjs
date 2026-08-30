# Diary Project Architecture & Development Guidelines

このプロジェクトは、単一の Phoenix Web アプリケーション（Single App）構造を維持しながら、ディレクトリとモジュール空間により複数のサブドメインサービスを管理・拡張する **Single-App Multi-Service** アーキテクチャを採用しています。

AIアシスタントおよび開発者は、新規機能の追加・リファクタリング時に以下のディレクトリ構成と設計原則に厳格に従ってください。

---

## 🏛 アーキテクチャ基本方針

1. **Single App + Strict Boundary (単一アプリ＋厳格なドメイン境界)**
   - 複雑化を避けるため Umbrella 構成は採用せず、単一の Phoenix アプリ内でサービスごとのディレクトリ境界を保ちます。
   - 異なるサービス間のロジックの混同を避け、カプセル化を意識してください。

2. **共通機能の階層的カプセル化**
   - ドメインロジック（`lib/diary/`）および Web/UI層（`lib/diary_web/`）は、共通機能（`shared`）とサービス個別機能（`services/`）に明確に分けて配置します。

---

## 📁 ディレクトリ構成ルール

```text
lib/
├── diary/                          # 🧠 [コア・ビジネスロジック (Contexts)]
│   ├── shared/                     # 全サービス共通のドメイン (Accounts, Storage 等)
│   │   ├── accounts.ex
│   │   └── storage.ex
│   │
│   └── services/                   # 🚀 サービスごとの独立ドメイン
│       ├── gym/                    # Gymサービス専用コンテキスト
│       │   ├── workout.ex
│       │   └── master.ex
│       └── <service_b>/            # 今後追加されるサービス
│
└── diary_web/                      # 🌐 [Webプレゼンテーション層]
    ├── components/                 # 🧩 [コンポーネント群]
    │   ├── core_components.ex      # 汎用アトミックUIパーツ (Button, Input, Modal等)
    │   ├── shared/                 # 複数サービス共通の複合UIパーツ (UserMenu, Avatar等)
    │   └── services/               # サービス専用UIコンポーネント
    │       └── gym/
    │
    ├── live/                       # ⚡ [LiveView 画面]
    │   ├── gym/                    # gym.example.com 用 LiveView
    │   │   ├── diary_live.ex
    │   │   └── workout_live.ex
    │   ├── shared/                 # 全サービス共通画面 (Login, Settings等)
    │   │   └── user_settings_live.ex
    │   └── <service_b>/
    │
    ├── controllers/                # 🎮 [Controller / API]
    │   └── gym/
    │
    ├── plugs/                      # 🔌 [共通Plug]
    │   ├── host_guard.ex
    │   └── fetch_subdomain.ex
    │
    └── router.ex                   # 🚦 [サブドメインルーティング]
```

---

## 🚦 サブドメインルーティング方針 (`router.ex`)

新規サービスを追加する際は、`router.ex` で `host:` オプションを指定した `scope` を定義し、Webリクエストをサブドメインごとに分離します。

```elixir
# Router example for multi-subdomain routing
defmodule DiaryWeb.Router do
  use DiaryWeb, :router

  # Subdomain scope for Gym application
  scope "/", DiaryWeb.Gym, host: ["gym.", "gym.localhost"] do
    pipe_through [:browser, :require_authenticated_user]

    live_session :gym_session, on_mount: [{DiaryWeb.UserAuth, :require_authenticated}] do
      live "/", DiaryLive, :index
      live "/workout", WorkoutLive, :index
    end
  end

  # Subdomain scope for future Service B
  # scope "/", DiaryWeb.ServiceB, host: ["service_b.", "service_b.localhost"] do ... end
end
```

---

## 🛠 開発コマンド & i18n (多言語化)

開発環境は Docker Compose で動作しています。翻訳ファイル（Gettext）の更新やコンパイルは `Makefile` を通して実行します。

```sh
# Extract i18n strings, merge po files, and compile application
make locale
```

---

## 📝 テンプレート書き方・コーディング規約 (HEEx Template Rules)

### HEEx テンプレートにおけるコメント構文
Phoenix / LiveView (`.heex`, `.html.heex`) テンプレートでコメントを記述する場合は、最新の **`<%!-- ... --%>`** 構文を使用してください。

```heex
<%!-- Recommended: Server-side comment (Will NOT be rendered in HTML output) --%>
<div class="example">
  <%!-- Use this syntax instead of the deprecated <%# ... %> --%>
  <p>Content</p>
</div>

<!-- Client-side HTML comment (Will be rendered in browser DOM source) -->
```

- ❌ 非推奨: `<%# コメント %>` （コンパイル時警告が出ます）
- ⭕️ 推奨: `<%!-- コメント --%>` （HTML出力に含まれないサーバーサイドコメント）

---

## 🤖 AI アシスタントへの指示 (Instructions for AI)

- コード生成やディレクトリ作成を行う際は、上記の `services/<service_name>` 境界を必ず遵守してください。
- サービス固有のロジックやUIを `shared` や `core_components.ex` に直接混入させないでください。
- コンポーネントを作成する際は、再利用性（`shared/`）とサービス固有性（`services/<service_name>/`）を常に判断して適切なディレクトリに配置してください。
- HEEx テンプレート (`.heex`, `.html.heex`) 内のコメントアウトには、非推奨の `<%# ... %>` ではなく、必ず **`<%!-- ... --%>`** 構文を使用してください。
