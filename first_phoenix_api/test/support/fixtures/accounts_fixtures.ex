defmodule FirstPhoenixApi.AccountsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `FirstPhoenixApi.Accounts` context.
  """

  @doc """
  Generate a user.
  """
  def user_fixture(attrs \\ %{}) do
    {:ok, user} =
      attrs
      |> Enum.into(%{
        email: "some email",
        name: "some name"
      })
      |> FirstPhoenixApi.Accounts.create_user()

    user
  end
end
