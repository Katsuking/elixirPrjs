defmodule Hello.Blog do
  alias Hello.Blog.Post
  alias Hello.Repo

  @doc """
  全件取得
  """
  def list_posts do
    Repo.all(Post)
  end

  @doc """
  1件のみ取得
  """
  def get_post!(id) do
    Repo.get!(Post, id)
  end
end
