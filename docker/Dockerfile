FROM elixir:1.17.2

# APTのキーに関する危険な使用法についての警告を無効にします。
ENV APT_KEY_DONT_WARN_ON_DANGEROUS_USAGE=DontWarn

# パッケージインストール時の対話的なプロンプト表示を抑制します。
ENV DEBIAN_FRONTEND noninteractive

# Debconfパッケージ設定システムからの警告を無効にします。
ENV DEBCONF_NOWARNINGS yes

RUN apt-get update && apt-get -y install apt-file && apt-file update
RUN apt-get -y upgrade

RUN apt-get -y install bash git vim sudo curl inotify-tools cmake erlang-dev ca-certificates gnupg

# APTのキーリングを保存するディレクトリを作成します。
RUN mkdir -p /etc/apt/keyrings

# NodeSourceのGPG公開キーを取得し、APTのキーリングに追加します。
RUN curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | \
    gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg

# Node.js 22のパッケージリポジトリをAPTのソースリストに追加します。
# パッケージリストを再度更新し、Node.jsをインストールします。
ENV NODE_MAJOR=22
RUN echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_$NODE_MAJOR.x nodistro main" > /etc/apt/sources.list.d/nodesource.list
RUN apt-get update && apt-get -y install nodejs

ARG UID=1000
ARG GID=1000

RUN groupadd -g $GID devel
RUN useradd -u $UID -g devel -m devel
RUN echo "devel ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

COPY --chown=devel:devel . /app

USER devel

WORKDIR /app

# ElixirのパッケージマネージャであるHexを強制的にローカルにインストールします。
RUN mix local.hex --force
# ErlangのビルドツールであるRebarを強制的にローカルにインストールします。
RUN mix local.rebar --force
