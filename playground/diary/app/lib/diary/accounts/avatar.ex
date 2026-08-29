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
  """
  def url(email) when is_binary(email) do
    normalized_email = String.downcase(String.trim(email))
    hash = :crypto.hash(:sha256, normalized_email) |> Base.encode16(case: :lower)
    "/uploads/avatars/#{hash}.png"
  end

  def url(_), do: nil
end
