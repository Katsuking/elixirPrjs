defmodule Diary.Accounts.Avatar do
  @moduledoc """
  Provides functions for calculating avatar S3 keys and public URLs based on user email hashes.
  """

  @doc """
  Generates a SHA256-based S3 object path for a given user email.
  """
  def s3_key(email) when is_binary(email) do
    normalized_email = String.downcase(String.trim(email))
    hash = :crypto.hash(:sha256, normalized_email) |> Base.encode16(case: :lower)
    "avatars/#{hash}.png"
  end

  def s3_key(_), do: nil

  @doc """
  Generates the relative public URL path for displaying the avatar.
  Supports an optional version timestamp for cache busting.
  """
  def url(email, version \\ nil)

  def url(email, version) when is_binary(email) do
    normalized_email = String.downcase(String.trim(email))
    hash = :crypto.hash(:sha256, normalized_email) |> Base.encode16(case: :lower)
    base_url = "/uploads/avatars/#{hash}.png"

    case version do
      nil -> base_url
      v -> "#{base_url}?v=#{v}"
    end
  end

  def url(_, _), do: nil
end
