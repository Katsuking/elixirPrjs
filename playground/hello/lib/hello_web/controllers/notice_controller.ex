defmodule HelloWeb.NoticeController do
  use HelloWeb, :controller

  alias Hello.Announcements
  alias Hello.Announcements.Notice

  action_fallback HelloWeb.FallbackController

  def index(conn, _params) do
    # notices = Announcements.list_notices()
    notices = Announcements.list_elixir_inclued("Elixir")
    render(conn, :index, notices: notices)
  end

  def create(conn, %{"notice" => notice_params}) do
    with {:ok, %Notice{} = notice} <- Announcements.create_notice(notice_params) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", ~p"/api/notices/#{notice}")
      |> render(:show, notice: notice)
    end
  end

  def show(conn, %{"id" => id}) do
    notice = Announcements.get_notice!(id)
    render(conn, :show, notice: notice)
  end

  def update(conn, %{"id" => id, "notice" => notice_params}) do
    notice = Announcements.get_notice!(id)

    with {:ok, %Notice{} = notice} <- Announcements.update_notice(notice, notice_params) do
      render(conn, :show, notice: notice)
    end
  end

  def delete(conn, %{"id" => id}) do
    notice = Announcements.get_notice!(id)

    with {:ok, %Notice{}} <- Announcements.delete_notice(notice) do
      send_resp(conn, :no_content, "")
    end
  end
end
