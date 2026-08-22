defmodule DiaryWeb.Plugs.HostGuardTest do
  use DiaryWeb.ConnCase, async: true
  alias DiaryWeb.Plugs.HostGuard

  # Save the original allowed hosts configuration and restore it after tests
  setup do
    original = Application.get_env(:diary, :allowed_hosts)
    on_exit(fn ->
      Application.put_env(:diary, :allowed_hosts, original)
    end)
    :ok
  end

  test "allows request if host is in the whitelisted hosts", %{conn: conn} do
    Application.put_env(:diary, :allowed_hosts, ["localhost"])

    # Simulate connection with localhost Host header
    conn =
      %{conn | host: "localhost"}
      |> HostGuard.call([])

    # Connection should not be halted and status should not be 404
    refute conn.halted
    assert conn.status != 404
  end

  test "halts and returns 404 error if host is not whitelisted", %{conn: conn} do
    Application.put_env(:diary, :allowed_hosts, ["localhost"])

    # Simulate connection with unallowed Host header
    conn =
      %{conn | host: "gym.wayup.cc"}
      |> HostGuard.call([])

    # Connection should be halted and response status should be 404
    assert conn.halted
    assert conn.status == 404
    assert conn.resp_body =~ "Not Found"
  end
end
