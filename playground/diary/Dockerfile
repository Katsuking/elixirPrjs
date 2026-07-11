# Use Elixir 1.19 to match the Livebook runtime compatibility requirement (~> 1.19.0)
FROM elixir:1.19-alpine


# Install necessary build tools and git
RUN apk add --no-cache build-base inotify-tools git

WORKDIR /app

# Mixのホームディレクトリを明示的に指定（環境変数の追加）
ENV MIX_HOME=/root/.mix

# HexとRebar（Elixirのパッケージ管理ツール）をインストール
RUN mix local.hex --force && \
    mix local.rebar --force

# Phoenixのインストーラーを取得
RUN mix archive.install hex phx_new --force

CMD ["mix", "phx.server"]
