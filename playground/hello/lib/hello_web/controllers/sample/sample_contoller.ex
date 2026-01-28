defmodule HelloWeb.Sample.SampleController do
  use HelloWeb, :controller
  alias Hello.Blog

  def index(conn, _params) do
    posts = Blog.list_posts()
    render(conn, :index, posts: posts)
  end
end
