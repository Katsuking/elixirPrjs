defmodule HelloWeb.Ping.PingJSON do
  # 引数として渡されたMap（辞書型）の中から、data というキーを探して、その中身を data という変数に放り込む
  def index(%{data: data}) do
    %{
      status: "ok",
      # data リストの中にある各 item に対して、data_item(item) という関数を実行しなさい。
      # その結果をまとめたリストを results に入れなさい」
      results: for(item <- data, do: data_item(item)) # for文ワンライナー
    }
  end

  @doc """
  単体表示用
  """
  def show(%{item: item}) do
    %{
      status: "ok",
      data: data_item(item)
    }
  end

  defp data_item(item) do
    %{
      id: item.id,
      name: item.name,
      message: item.message,
      inserted_at: item[:inserted_at] || DateTime.utc_now()
    }
  end
end
