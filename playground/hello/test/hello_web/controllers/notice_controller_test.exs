defmodule HelloWeb.NoticeControllerTest do
  use HelloWeb.ConnCase

  import Hello.AnnouncementsFixtures
  alias Hello.Announcements.Notice

  @create_attrs %{
    title: "some title",
    content: "some content",
    published_at: ~U[2026-01-27 12:12:00Z]
  }
  @update_attrs %{
    title: "some updated title",
    content: "some updated content",
    published_at: ~U[2026-01-28 12:12:00Z]
  }
  @invalid_attrs %{title: nil, content: nil, published_at: nil}

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "index" do
    test "lists all notices", %{conn: conn} do
      conn = get(conn, ~p"/api/notices")
      assert json_response(conn, 200)["data"] == []
    end
  end

  describe "create notice" do
    test "renders notice when data is valid", %{conn: conn} do
      conn = post(conn, ~p"/api/notices", notice: @create_attrs)
      assert %{"id" => id} = json_response(conn, 201)["data"]

      conn = get(conn, ~p"/api/notices/#{id}")

      assert %{
               "id" => ^id,
               "content" => "some content",
               "published_at" => "2026-01-27T12:12:00Z",
               "title" => "some title"
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, ~p"/api/notices", notice: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "update notice" do
    setup [:create_notice]

    test "renders notice when data is valid", %{conn: conn, notice: %Notice{id: id} = notice} do
      conn = put(conn, ~p"/api/notices/#{notice}", notice: @update_attrs)
      assert %{"id" => ^id} = json_response(conn, 200)["data"]

      conn = get(conn, ~p"/api/notices/#{id}")

      assert %{
               "id" => ^id,
               "content" => "some updated content",
               "published_at" => "2026-01-28T12:12:00Z",
               "title" => "some updated title"
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn, notice: notice} do
      conn = put(conn, ~p"/api/notices/#{notice}", notice: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "delete notice" do
    setup [:create_notice]

    test "deletes chosen notice", %{conn: conn, notice: notice} do
      conn = delete(conn, ~p"/api/notices/#{notice}")
      assert response(conn, 204)

      assert_error_sent 404, fn ->
        get(conn, ~p"/api/notices/#{notice}")
      end
    end
  end

  defp create_notice(_) do
    notice = notice_fixture()

    %{notice: notice}
  end
end
