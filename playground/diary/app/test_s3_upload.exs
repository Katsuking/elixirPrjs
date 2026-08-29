# test_s3_upload.exs
# This script verifies the connection to the S3-compatible storage
# by uploading a small dummy image using the Req and ReqS3 libraries.

# Ensure required applications (Req, Finch, etc.) are started when running outside of mix run (e.g. release eval)
Application.ensure_all_started(:req)

IO.puts("=== S3 Connection & Upload Verification Test ===")

# Retrieve S3 configurations from environment variables.
# These environment variables must be defined in your environment (e.g. via .envrc).
endpoint = System.get_env("S3_ENDPOINT")
bucket = System.get_env("S3_BUCKET")
access_key = System.get_env("S3_ACCESS_KEY_ID")
secret_key = System.get_env("S3_SECRET_ACCESS_KEY")
region = System.get_env("S3_REGION") || "garage"
region = if region in [nil, "", "us-east-1"], do: "garage", else: region

# IO.puts("Endpoint: #{endpoint}")
# IO.puts("Bucket:   #{bucket}")
# IO.puts("Region:   #{region}")

# Simple validation to ensure environment variables are present.
if is_nil(endpoint) or is_nil(bucket) or is_nil(access_key) or is_nil(secret_key) do
  IO.puts("[ERROR] Missing required S3 environment variables!")
  IO.puts("Please ensure S3_ENDPOINT, S3_BUCKET, S3_ACCESS_KEY_ID, and S3_SECRET_ACCESS_KEY are set.")
  System.halt(1)
end

# Map custom S3_ environment variables to standard AWS_ environment variables.
# This ensures Req and ReqS3 automatically pick them up without needing flaky manual options.
System.put_env("AWS_ACCESS_KEY_ID", access_key)
System.put_env("AWS_SECRET_ACCESS_KEY", secret_key)
System.put_env("AWS_REGION", region)
System.put_env("AWS_ENDPOINT_URL_S3", endpoint)

req =
  Req.new(aws_sigv4: [region: region])
  |> ReqS3.attach()

# A tiny 1x1 pixel transparent PNG image binary data to act as our test file.
dummy_image = <<137, 80, 78, 71, 13, 10, 26, 10, 0, 0, 0, 13, 73, 72, 68, 82, 0, 0, 0, 1, 0, 0, 0, 1, 8, 6, 0, 0, 0, 31, 21, 196, 137, 0, 0, 0, 10, 73, 68, 65, 84, 120, 156, 99, 0, 1, 0, 0, 5, 0, 1, 13, 10, 45, 180, 0, 0, 0, 0, 73, 69, 78, 68, 174, 66, 96, 130>>

# Target URL using the custom s3:// scheme processed by ReqS3.
s3_url = "s3://#{bucket}/test_upload_verify.png"
IO.puts("Uploading test image to #{s3_url}...")

# Execute the HTTP PUT request.
case Req.put(req, url: s3_url, body: dummy_image) do
  {:ok, %Req.Response{status: 200}} ->
    IO.puts("\n[SUCCESS] Successfully uploaded dummy image to S3 compatible storage!")

  {:ok, %Req.Response{status: status, body: body}} ->
    IO.puts("\n[FAILED] Upload request completed but returned status: #{status}")
    IO.puts("Response Body:")
    IO.inspect(body)

  {:error, exception} ->
    IO.puts("\n[ERROR] An error occurred during the HTTP request:")
    IO.inspect(exception)
end
