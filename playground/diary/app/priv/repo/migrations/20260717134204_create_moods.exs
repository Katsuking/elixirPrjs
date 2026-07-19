defmodule Diary.Repo.Migrations.CreateMoods do
  use Ecto.Migration

  def change do
    create table(:moods) do
      add :date, :date, null: false
      add :status, :string, null: false
      timestamps()
    end


    # Add a unique index to ensure only one mood is registered per date.
    create unique_index(:moods, [:date])

  end
end
