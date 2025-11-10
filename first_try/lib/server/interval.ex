defmodule Server.Interval do
  use GenServer

  @interval 5_000

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  @impl true
  def init(:ok) do
    schedule_work()
    {:ok, :ok}
  end

  @impl true
  def handle_info(:work, state) do
    do_work()
    schedule_work()
    {:noreply, state}
  end

  defp do_work() do
    IO.puts("[#{inspect(self())}] 定期ジョブを実行しました #{DateTime.utc_now()}")
  end

  defp schedule_work() do
    Process.send_after(self(), :work, @interval) # 5秒後
  end
end
