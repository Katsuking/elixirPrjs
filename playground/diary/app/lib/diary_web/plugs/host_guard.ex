defmodule DiaryWeb.Plugs.HostGuard do
  @moduledoc """
  Plug to restrict incoming requests to a whitelist of allowed hostnames.
  Rejects unhandled subdomains or invalid hosts with a 404 error page.
  """
  import Plug.Conn
  import Phoenix.Controller

  def init(opts), do: opts

  def call(conn, _opts) do
    # Fetch whitelisted hosts from configuration, default to localhost values
    allowed_hosts = Application.get_env(:diary, :allowed_hosts, ["localhost", "127.0.0.1"])

    # If the request host is in the allowed list, pass it through.
    # Otherwise, return a 404 error.
    if conn.host in allowed_hosts do
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
