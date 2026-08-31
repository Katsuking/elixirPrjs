# Use Debian-based Elixir image to match the production environment
FROM hexpm/elixir:1.19.5-erlang-28.5.0.2-debian-trixie-20260623-slim

# Install build dependencies, git, SSL certs, and utilities for Bun
RUN apt-get update \
  && apt-get install -y --no-install-recommends build-essential git curl unzip ca-certificates inotify-tools \
  && rm -rf /var/lib/apt/lists/*

# Install Bun directly using official installer
RUN curl -fsSL https://bun.sh/install | bash
ENV PATH="/root/.bun/bin:${PATH}"

WORKDIR /app

# Set Mix home directory
ENV MIX_HOME=/root/.mix

# Install Hex and Rebar
RUN mix local.hex --force && \
    mix local.rebar --force

# Install Phoenix installer archive
RUN mix archive.install hex phx_new --force

CMD ["mix", "phx.server"]
