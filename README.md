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

### migrate file

```sh
mix ecto.gen.migration create_posts
```

これがマイグレーションファイルにあたる

```elixir
defmodule Hello.Repo.Migrations.CreatePosts do
  use Ecto.Migration

  def change do
    create table(:posts) do
      add :title, :string
      add :body, :text

      timestamps() # inserted_at と updated_at が自動追加されます
    end
  end
end
```

以下、migrateコマンド

```sh
mix ecto.migrate
```

### テーブル作成に あわせてファイル生成

```sh
mix phx.gen.json Announcements Notice notices title:string content:text published_at:utc_datetime
```
