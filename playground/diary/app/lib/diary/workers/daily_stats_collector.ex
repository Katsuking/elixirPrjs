defmodule Diary.Workers.DailyStatsCollector do
  use Oban.Worker, queue: :default

  import Ecto.Query
  alias Diary.Repo
  alias Diary.Accounts.User
  alias Diary.Stats.DailyStat
  alias Diary.Workers.Notifier

  @impl Oban.Worker
  def perform(_job) do
    # Executed at JST 00:00 (UTC 15:00 previous day),
    # so Date.utc_today() naturally returns the target date (previous day).
    target_date = Date.utc_today()

    user_count =
      Repo.one(
        from u in User,
          where: not is_nil(u.confirmed_at) and is_nil(u.deleted_at),
          select: count(u.id)
      )

    # UPSERT the stats for the target date
    changeset = DailyStat.changeset(%DailyStat{}, %{date: target_date, user_count: user_count})

    case Repo.insert(changeset, on_conflict: [set: [user_count: user_count]], conflict_target: :date) do
      {:ok, _stat} ->
        # Enqueue notifications for Slack and Discord
        message = "Daily active user count for #{target_date}: #{user_count}"

        # Insert Slack notification
        %{channel: "slack", message: message}
        |> Notifier.new()
        |> Oban.insert()

        # Insert Discord notification
        %{channel: "discord", message: message}
        |> Notifier.new()
        |> Oban.insert()

        :ok

      {:error, reason} ->
        {:error, reason}
    end
  end
end
