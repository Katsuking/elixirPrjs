defmodule FirstStepWeb.HomeController do
  use FirstStepWeb, :controller

  def hello(conn, _param) do
    render(conn, :hello)
  end
end
