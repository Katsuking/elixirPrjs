### first thing first

- `mix setup` to install and setup dependencies
- Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

### DB初期化

```sh
mix ecto.reset
```

### DB migration マイグレーション

```sh
mix ecto.migrate
```

### aマイグレーションファイル作成

```sh
mix ecto.gen.migration <命名>
```
