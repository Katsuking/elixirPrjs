defmodule HelloLiveview.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      HelloLiveviewWeb.Telemetry,
      HelloLiveview.Repo,
      {DNSCluster, query: Application.get_env(:hello_liveview, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: HelloLiveview.PubSub},
      HelloLiveviewWeb.Presence,
      # Start a worker by calling: HelloLiveview.Worker.start_link(arg)
      # {HelloLiveview.Worker, arg},
      # Start to serve requests, typically the last entry
      HelloLiveviewWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: HelloLiveview.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    HelloLiveviewWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
