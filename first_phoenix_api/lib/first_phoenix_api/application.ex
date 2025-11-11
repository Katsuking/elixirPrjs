defmodule FirstPhoenixApi.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      FirstPhoenixApiWeb.Telemetry,
      FirstPhoenixApi.Repo,
      {DNSCluster, query: Application.get_env(:first_phoenix_api, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: FirstPhoenixApi.PubSub},
      # Start a worker by calling: FirstPhoenixApi.Worker.start_link(arg)
      # {FirstPhoenixApi.Worker, arg},
      # Start to serve requests, typically the last entry
      FirstPhoenixApiWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: FirstPhoenixApi.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    FirstPhoenixApiWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
