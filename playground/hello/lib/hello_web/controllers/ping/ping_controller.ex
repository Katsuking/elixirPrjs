defmodule HelloWeb.Ping.PingController do
  use HelloWeb, :controller

  def index(conn, _params) do # url param 取得なし
    # 本来はDBから取得したデータのリスト
    data = [
      %{id: 1, name: "API Test", message: "Working!"},
      %{id: 2, name: "Hello", message: "Phoenix is fast"}
    ]

    # render の第3引数で渡した %{data: data} が、
    # そのまま PingJSON.index(%{data: data}) の引数に「放り込まれ」ます！
    render(conn, HelloWeb.Ping.PingJSON, :index, data: data)
  end

  # url param を取得できる
  def show(conn, %{"id" => id}) do
    # 本来はDBから特定のIDで検索した1つのデータ
    item = %{id: String.to_integer(id), name: "Single Item", message: "Search ID: #{id}"}

    # render の第3引数で渡した %{item: item} が、
    # そのまま PingJSON.show(%{item: item}) の引数に放り込まれる
    render(conn, :show, item: item)
  end
end
