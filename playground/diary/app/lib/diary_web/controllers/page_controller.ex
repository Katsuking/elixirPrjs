defmodule DiaryWeb.PageController do
  use DiaryWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
