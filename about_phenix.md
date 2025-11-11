### refs

[about elixir](./README.md)

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
