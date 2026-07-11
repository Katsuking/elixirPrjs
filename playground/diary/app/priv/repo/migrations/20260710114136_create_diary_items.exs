defmodule Diary.Repo.Migrations.CreateDiaryItems do
  use Ecto.Migration

  def change do
    # Create the diary_items table to store daily bullet points
    create table(:diary_items) do
      add :date, :date, null: false
      add :content, :string, null: false
      add :position, :integer, null: false, default: 0

      timestamps()
    end

    # Add an index for faster lookups by date and ordering by position
    create index(:diary_items, [:date, :position])
  end
end
