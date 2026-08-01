defmodule Diary.Workers.DailyStatsCollectorTest do
  use Diary.DataCase, async: true
  use Oban.Testing, repo: Diary.Repo

  alias Diary.Workers.DailyStatsCollector
  alias Diary.Stats.DailyStat
  alias Diary.Accounts.User
  import Diary.AccountsFixtures
  import Ecto.Query

  test "collects active users and records statistics, then enqueues notifications" do
    # Create active user (confirmed, not deleted)
    _user1 = user_fixture()

    # Create unconfirmed user (unconfirmed_user_fixture registers but doesn't log in via magic link, leaving confirmed_at as nil)
    _user2 = unconfirmed_user_fixture()

    # Create deleted user (confirmed but soft-deleted)
    user3 = user_fixture()
    Repo.update_all(from(u in User, where: u.id == ^user3.id), set: [deleted_at: DateTime.utc_now()])

    # Perform the collector job
    assert :ok = perform_job(DailyStatsCollector, %{})

    # Verify stats was saved in database
    today = Date.utc_today()
    # user1 is confirmed (via user_fixture) -> active
    # user2 is unconfirmed (via unconfirmed_user_fixture) -> unconfirmed_at is nil
    # user3 is confirmed (via user_fixture) and then soft-deleted -> deleted
    # Therefore, count of active users (confirmed AND not deleted) should be 1 (only user1).
    assert %DailyStat{user_count: 1} = Repo.get_by(DailyStat, date: today)

    # Verify notifications were enqueued in Oban
    assert_enqueued(worker: Diary.Workers.Notifier, args: %{"channel" => "slack", "message" => "Daily active user count for #{today}: 1"})
    assert_enqueued(worker: Diary.Workers.Notifier, args: %{"channel" => "discord", "message" => "Daily active user count for #{today}: 1"})
  end
end
