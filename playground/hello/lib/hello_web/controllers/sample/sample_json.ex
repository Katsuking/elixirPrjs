defmodule HelloWeb.Sample.SampleJSON do
  def index(%{posts: posts}) do
    IO.inspect(posts, label: "posts")
    # time = DateTime.utc_now() |> DateTime.to_iso8601()
    # Map.put(posts, :server_time, time)
    # data = for(post <- posts, do: data_item(post))
    %{ data: for(post <- posts, do: data_item(post)) }
  end

  defp data_item(post) do
    %{
      id: post.id,
      title: post.title,
      body: post.body,
      inserted_at: post.inserted_at
    }
  end
end
