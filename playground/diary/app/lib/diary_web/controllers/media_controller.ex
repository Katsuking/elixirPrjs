defmodule DiaryWeb.MediaController do
  use DiaryWeb, :controller

  alias Diary.Storage

  # 3 days cache in seconds (86,400 * 3)
  @cache_control_header "public, max-age=259200"

  @doc """
  Serves media files stored in S3/Garage through Phoenix proxy with caching headers.
  """
  def show(conn, %{"path" => path_segments}) do
    key = Enum.join(path_segments, "/")

    client_etag = get_req_header(conn, "if-none-match") |> List.first()

    case Storage.get_object(key) do
      {:ok, %{body: body, content_type: content_type, etag: etag}} ->
        if client_etag && etag && client_etag == etag do
          conn
          |> put_resp_header("cache-control", @cache_control_header)
          |> put_resp_header("etag", etag)
          |> send_resp(304, "")
        else
          conn
          |> put_resp_content_type(content_type)
          |> put_resp_header("content-disposition", "inline")
          |> put_resp_header("cache-control", @cache_control_header)
          |> maybe_put_etag(etag)
          |> send_resp(200, body)
        end

      {:error, :not_found} ->
        conn
        |> send_resp(404, "File Not Found")

      {:error, _reason} ->
        conn
        |> send_resp(500, "Internal Server Error")
    end
  end

  defp maybe_put_etag(conn, etag) when is_binary(etag) do
    put_resp_header(conn, "etag", etag)
  end

  defp maybe_put_etag(conn, _), do: conn
end
