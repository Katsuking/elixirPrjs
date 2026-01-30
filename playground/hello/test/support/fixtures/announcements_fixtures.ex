defmodule Hello.AnnouncementsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Hello.Announcements` context.
  """

  @doc """
  Generate a notice.
  """
  def notice_fixture(attrs \\ %{}) do
    {:ok, notice} =
      attrs
      |> Enum.into(%{
        content: "some content",
        published_at: ~U[2026-01-27 12:12:00Z],
        title: "some title"
      })
      |> Hello.Announcements.create_notice()

    notice
  end
end
