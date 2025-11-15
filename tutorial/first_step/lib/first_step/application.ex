defmodule FirstStep.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      FirstStepWeb.Telemetry,
      {DNSCluster, query: Application.get_env(:first_step, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: FirstStep.PubSub},
      # Start a worker by calling: FirstStep.Worker.start_link(arg)
      # {FirstStep.Worker, arg},
      # Start to serve requests, typically the last entry
      FirstStepWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: FirstStep.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    FirstStepWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
