defmodule Server.Application do
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      Server.Interval
    ]

    Supervisor.start_link(children, [strategy: :one_for_one, name: Server.Application])
  end
end
