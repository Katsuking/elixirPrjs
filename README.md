### refs

- [Phoenix 実際にエンドポイントを作成する流れを確認する](./about_phenix.md)

### elixir version

```sh
elixir -v
```

### linux 環境のみの設定

[linux 環境でのホットリロード](https://github.com/inotify-tools/inotify-tools/wiki)

```sh
sudo apt-get install inotify-tools
```

### elixir mix

新規作成

```sh
mix new <project name here>
```

### phoenix を使って API を開発してみる

```sh
mix archive.install hex phx_new # 一度実行するだけ
mix phx.new <prj name here> # プロジェクトの新規作成
```

単純な REST API を作成するだけなら以下の通り

```sh
mix phx.new <prjname> --no-html --no-assets --no-live
```

e.g. `mix phx.new hello --no-html --no-assets --binary-id --no-live`

Then configure your database in config/dev.exs and run:

```sh
mix ecto.create
```

Start your Phoenix app with:

```sh
mix phx.server
```

mix phx.new first_phoenix_api --no-html --no-assets --no-live

auth とかも組み込みであるみたい

[phoenix](https://phoenixframework.org/)

# Phoenix 実際にエンドポイントを作成する流れを確認する

### API 用ファイルとスキーマの生成

mix phx.gen.json: JSON API 用のファイルを生成するジェネレーターの指定。
Accounts: 生成されるモジュール名
User: スキーマ名/リソース名。生成される Ecto スキーマ
users: データベースのテーブル名。生成されるマイグレーションファイルで使用されます。
name:string email:string: スキーマとマイグレーションに追加するフィールド名と型。

```sh
mix phx.gen.json Accounts User users name:string email:string
```

以下生成される

```
* creating lib/first_phoenix_api_web/controllers/user_controller.ex
* creating lib/first_phoenix_api_web/controllers/user_json.ex
* creating lib/first_phoenix_api_web/controllers/changeset_json.ex
* creating test/first_phoenix_api_web/controllers/user_controller_test.exs
* creating lib/first_phoenix_api_web/controllers/fallback_controller.ex
* creating lib/first_phoenix_api/accounts/user.ex
* creating priv/repo/migrations/20251111114454_create_users.exs
* creating lib/first_phoenix_api/accounts.ex
* injecting lib/first_phoenix_api/accounts.ex
* creating test/first_phoenix_api/accounts_test.exs
* injecting test/first_phoenix_api/accounts_test.exs
* creating test/support/fixtures/accounts_fixtures.ex
* injecting test/support/fixtures/accounts_fixtures.ex
```

エンドポイントの追加
first_phoenix_api/lib/first_phoenix_api_web/router.ex

```elixir
scope "/api", FirstPhoenixApiWeb do
  pipe_through :api

  resources "/users", UserController, only: [:index, :show, :create, :update, :delete] # これを追加
end
```

マイグレーションして、user テーブルを作成する

```sh
mix ecto.migrate
```
