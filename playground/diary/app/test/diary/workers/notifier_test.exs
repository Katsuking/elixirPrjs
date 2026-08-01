defmodule Diary.Workers.NotifierTest do
  use Diary.DataCase, async: true
  use Oban.Testing, repo: Diary.Repo

  alias Diary.Workers.Notifier

  setup do
    # Set dummy webhook URLs for test execution
    System.put_env("SLACK_WEBHOOK_URL", "http://slack.mock")
    System.put_env("DISCORD_WEBHOOK_URL", "http://discord.mock")

    on_exit(fn ->
      System.delete_env("SLACK_WEBHOOK_URL")
      System.delete_env("DISCORD_WEBHOOK_URL")
    end)

    :ok
  end

  test "sends slack notification successfully" do
    Req.Test.stub(Notifier, fn conn ->
      {:ok, body, conn} = Plug.Conn.read_body(conn)
      assert %{"text" => "Hello Slack!"} = Jason.decode!(body)
      Req.Test.json(conn, %{ok: true})
    end)

    assert :ok = perform_job(Notifier, %{"channel" => "slack", "message" => "Hello Slack!"})
  end

  test "sends discord notification successfully" do
    Req.Test.stub(Notifier, fn conn ->
      {:ok, body, conn} = Plug.Conn.read_body(conn)
      assert %{"content" => "Hello Discord!"} = Jason.decode!(body)
      Req.Test.json(conn, %{ok: true})
    end)

    assert :ok = perform_job(Notifier, %{"channel" => "discord", "message" => "Hello Discord!"})
  end

  test "skips execution if webhook URL is missing" do
    System.delete_env("SLACK_WEBHOOK_URL")

    # This should return :ok without hitting Req.Test
    assert :ok = perform_job(Notifier, %{"channel" => "slack", "message" => "Hello Slack!"})
  end
end
