defmodule Diary.Workers.Notifier do
  use Oban.Worker, queue: :default

  require Logger

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"channel" => channel, "message" => message}}) do
    case get_webhook_url(channel) do
      nil ->
        Logger.warning("Webhook URL for channel #{channel} is not configured. Skipping notification.")
        :ok

      url ->
        payload = format_payload(channel, message)

        case Req.post(url, [json: payload] ++ req_options()) do
          {:ok, %Req.Response{status: status}} when status in 200..299 ->
            :ok

          {:ok, %Req.Response{status: status, body: body}} ->
            Logger.error("Failed to send notification to #{channel}. Status: #{status}, Body: #{inspect(body)}")
            {:error, "HTTP error status: #{status}"}

          {:error, reason} ->
            Logger.error("Failed to send notification to #{channel}. Reason: #{inspect(reason)}")
            {:error, reason}
        end
    end
  end

  defp req_options do
    Application.get_env(:diary, :notifier_req_options, [])
  end

  defp get_webhook_url("slack"), do: System.get_env("SLACK_WEBHOOK_URL")
  defp get_webhook_url("discord"), do: System.get_env("DISCORD_WEBHOOK_URL")
  defp get_webhook_url(_), do: nil

  defp format_payload("slack", message), do: %{text: message}
  defp format_payload("discord", message), do: %{content: message}
  defp format_payload(_, message), do: %{text: message}
end
