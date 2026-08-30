defmodule Diary.Storage do
  @moduledoc """
  Interface module for interacting with S3 / Garage compatible storage using Req and ReqS3.
  """

  @doc """
  Fetches an object from the S3 storage by its key.

  Returns `{:ok, %{body: binary, content_type: string, etag: string}}` or `{:error, reason}`.
  """
  def get_object(key) when is_binary(key) do
    bucket = fetch_config("S3_BUCKET")
    endpoint = fetch_config("S3_ENDPOINT")
    access_key = fetch_config("S3_ACCESS_KEY_ID")
    secret_key = fetch_config("S3_SECRET_ACCESS_KEY")
    region = fetch_region()

    if is_nil(endpoint) or is_nil(bucket) or is_nil(access_key) or is_nil(secret_key) do
      {:error, :missing_s3_config}
    else
      # Set AWS environment variables for ReqS3 compatibility
      System.put_env("AWS_ACCESS_KEY_ID", access_key)
      System.put_env("AWS_SECRET_ACCESS_KEY", secret_key)
      System.put_env("AWS_REGION", region)
      System.put_env("AWS_ENDPOINT_URL_S3", endpoint)

      s3_url = "s3://#{bucket}/#{key}"

      req =
        Req.new(aws_sigv4: [region: region])
        |> ReqS3.attach()

      case Req.get(req, url: s3_url) do
        {:ok, %Req.Response{status: 200, body: body, headers: headers}} ->
          content_type = get_header(headers, "content-type") || "application/octet-stream"
          etag = get_header(headers, "etag")
          {:ok, %{body: body, content_type: content_type, etag: etag}}

        {:ok, %Req.Response{status: 404, body: body}} ->
          require Logger
          Logger.warning("[Storage] S3 404 Not Found for url #{s3_url}, body: #{inspect(body)}")
          {:error, :not_found}

        {:ok, %Req.Response{status: status, body: body}} ->
          require Logger
          Logger.error("[Storage] S3 Error #{status} for url #{s3_url}, body: #{inspect(body)}")
          {:error, {:s3_error, status, body}}

        {:error, reason} ->
          require Logger
          Logger.error("[Storage] Req Error for url #{s3_url}: #{inspect(reason)}")
          {:error, reason}
      end
    end
  end

  @doc """
  Uploads binary data to S3 storage at the specified key.
  """
  def put_object(key, body, opts \\ []) when is_binary(key) and is_binary(body) do
    bucket = fetch_config("S3_BUCKET")
    endpoint = fetch_config("S3_ENDPOINT")
    access_key = fetch_config("S3_ACCESS_KEY_ID")
    secret_key = fetch_config("S3_SECRET_ACCESS_KEY")
    region = fetch_region()

    if is_nil(endpoint) or is_nil(bucket) or is_nil(access_key) or is_nil(secret_key) do
      {:error, :missing_s3_config}
    else
      System.put_env("AWS_ACCESS_KEY_ID", access_key)
      System.put_env("AWS_SECRET_ACCESS_KEY", secret_key)
      System.put_env("AWS_REGION", region)
      System.put_env("AWS_ENDPOINT_URL_S3", endpoint)

      s3_url = "s3://#{bucket}/#{key}"
      headers = Keyword.get(opts, :headers, [])

      req =
        Req.new(aws_sigv4: [region: region], headers: headers)
        |> ReqS3.attach()

      case Req.put(req, url: s3_url, body: body) do
        {:ok, %Req.Response{status: 200}} ->
          {:ok, s3_url}

        {:ok, %Req.Response{status: status, body: resp_body}} ->
          {:error, {:s3_error, status, resp_body}}

        {:error, reason} ->
          {:error, reason}
      end
    end
  end

  defp fetch_config(key) do
    System.get_env(key)
  end

  defp fetch_region do
    region = System.get_env("S3_REGION") || "garage"
    if region in [nil, "", "us-east-1"], do: "garage", else: region
  end

  defp get_header(headers, header_name) do
    case Map.get(headers, header_name) do
      [val | _] -> val
      val when is_binary(val) -> val
      _ -> nil
    end
  end
end
