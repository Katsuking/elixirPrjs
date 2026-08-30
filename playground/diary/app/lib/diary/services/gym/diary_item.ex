defmodule Diary.DiaryItem do
  @moduledoc """
  Schema definition for a single diary bullet point.
  """
  use Ecto.Schema
  import Ecto.Changeset

  schema "diary_items" do
    # Content of the diary item, limited to 50 characters
    field :content, :string
    # The date this diary item belongs to
    field :date, :date
    # Display position for ordering items within the same day
    field :position, :integer, default: 0
    # Associate with User schema for multi-tenant isolation
    belongs_to :user, Diary.Accounts.User

    timestamps()
  end

  @doc """
  Generates a changeset for validating and storing a diary item.
  """
  def changeset(diary_item, attrs \\ %{}) do
    diary_item
    |> cast(attrs, [:content, :date, :position, :user_id])
    |> validate_required([:content, :date, :user_id])
    # Ensure the content length does not exceed 50 characters
    |> validate_length(:content, max: 50)
  end
end
