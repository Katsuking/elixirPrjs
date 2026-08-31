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

## ⚡️ JS Hook ディレクトリ分割ルール (`assets/js/hooks/`)

Phoenix LiveView の `phx-hook` で使用する JS Hook は、`app.js` に直書きせず、`assets/js/hooks/` 配下にモジュール分割して作成・インポートします。

```text
assets/js/
├── app.js                 # エントリポイント & Hooks の集約インポート
├── utils/                 # ユーティリティモジュール (例: h3_calculator.js)
└── hooks/
    ├── index.js           # 全 Hooks をエクスポートする集約ファイル
    ├── shared/            # 共通 Hook (例: geolocation.js, theme.js 等)
    └── services/          # サービス固有 Hook (例: gym/timer.js 等)
```

---

## 🗺 位置情報・H3 空間インデックス仕様 (`h3-js` / Bun)

位置情報の取得およびプライバシー配慮のため、Uber の **H3 Spatial Indexing Library (`h3-js`)** を導入しています。

### フロントエンドパッケージ管理 (Bun)

- アセットディレクトリ (`app/assets`) 内のパッケージ管理には **Bun** を採用しています (`package.json`, `bun.lock`)。
- JS の単体テストは `cd app/assets && bun test` で実行可能です。

### 位置情報の粗視化（プライバシー保護とマルチ解像度）

ブラウザの Geolocation API で取得した正確な緯度・経度は、`assets/js/utils/h3_calculator.js` 内で H3 セルインデックスに変換され、粗視化（おおよその位置情報）された上で Phoenix LiveView サーバーへ送信されます。

- **Resolution 8（近隣レベル / 一辺 約460m, 面積 約0.73 km²）**: 近隣施設のマッチングや精度の高いチェックイン判定に使用。
- **Resolution 7（広域レベル / 一辺 約1.2km, 面積 約5.16 km²）**: プライバシーを配慮したおおよその地域表示や広域集計に使用。

正確な座標に加えて H3 インデックスおよびセル中心の概算座標を扱うことで、ユーザーのプライバシーに考慮した「おおよその位置情報」の保持・活用が可能です。

---

## 🤖 AI アシスタントへの指示 (Instructions for AI)

- コード生成やディレクトリ作成を行う際は、上記の `services/<service_name>` 境界を必ず遵守してください。
- サービス固有のロジックやUIを `shared` や `core_components.ex` に直接混入させないでください。
- コンポーネントを作成する際は、再利用性（`shared/`）とサービス固有性（`services/<service_name>/`）を常に判断して適切なディレクトリに配置してください。
- HEEx テンプレート (`.heex`, `.html.heex`) 内のコメントアウトには、非推奨の `<%# ... %>` ではなく、必ず **`<%!-- ... --%>`** 構文を使用してください。
- LiveView の JS Hook を作成する際は `app.js` に直接定義せず、必ず `assets/js/hooks/shared/` または `assets/js/hooks/services/<service_name>/` 配下に分割作成し、`assets/js/hooks/index.js` からインポートしてください。
- JS パッケージを追加・利用する際は `app/assets` 配下で **Bun (`bun`)** を使用してください。
