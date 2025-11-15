defmodule FirstStepWeb.HomeController do
  use FirstStepWeb, :controller

  def index(conn, _param) do
    render(conn, :index)
  end

  def hello(conn, _param) do
    render(conn, :hello)
  end
end
