defmodule HelloWeb.PingController do
  use HelloWeb, :controller

  def index(conn, _params) do
    json(conn, %{
      status: "ok",
      message: "Hello, this is a normal API!",
      data: %{id: 1, name: "Phoenix User"}
    })
  end
end
