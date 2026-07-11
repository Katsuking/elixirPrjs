defmodule Diary.Application do
  # See https://elixir.hexdocs.pm/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      DiaryWeb.Telemetry,
      Diary.Repo,
      {DNSCluster, query: Application.get_env(:diary, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Diary.PubSub},
      # Start a worker by calling: Diary.Worker.start_link(arg)
      # {Diary.Worker, arg},
      # Start to serve requests, typically the last entry
      DiaryWeb.Endpoint
    ]

    # See https://elixir.hexdocs.pm/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Diary.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    DiaryWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
