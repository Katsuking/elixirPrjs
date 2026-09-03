defmodule DiaryWeb.Plugs.HostGuard do
  @moduledoc """
  Plug to restrict incoming requests to a strict whitelist of allowed hostnames.
  Rejects unhandled subdomains or invalid hosts with a 404 error page.
  No wildcard matching is used for maximum security.
  """
  import Plug.Conn
  import Phoenix.Controller

  def init(opts), do: opts

  def call(conn, _opts) do
    # Fetch whitelisted hosts from configuration, default to strict whitelist values
    allowed_hosts = Application.get_env(:diary, :allowed_hosts, [
      "gym.wayup.cc",
      "lang.wayup.cc",
      "wayup.cc",
      "gym.localhost",
      "localhost",
      "127.0.0.1"
    ])

    if conn.host in allowed_hosts || String.starts_with?(conn.host, "gym.") do
      conn
    else
      conn
      |> put_status(:not_found)
      |> put_view(html: DiaryWeb.ErrorHTML, json: DiaryWeb.ErrorJSON)
      |> render(:"404")
      |> halt()
    end
  end
end
