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

[Phoenix 実際にエンドポイントを作成する流れを確認する](./about_phenix.md)

###
