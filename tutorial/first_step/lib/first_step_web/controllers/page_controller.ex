defmodule FirstStepWeb.PageController do
  use FirstStepWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
