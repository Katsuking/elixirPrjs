defmodule Diary.Repo.Migrations.CreateDailyStats do
  use Ecto.Migration

  def change do
    create table(:daily_stats) do
      add :date, :date, null: false
      add :user_count, :integer, null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:daily_stats, [:date])
  end
end
