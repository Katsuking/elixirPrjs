defmodule DiaryWeb.HealthController do
  @moduledoc """
  Lightweight healthcheck controller for load balancers and container health monitoring.
  """
  use DiaryWeb, :controller

  def show(conn, _params) do
    # Return HTTP 200 OK JSON response for health checking
    json(conn, %{status: "ok"})
  end
end
