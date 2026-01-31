defmodule HelloLiveviewWeb.PageController do
  use HelloLiveviewWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
