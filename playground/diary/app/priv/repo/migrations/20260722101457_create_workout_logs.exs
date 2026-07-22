defmodule Diary.Repo.Migrations.CreateWorkoutLogs do
  use Ecto.Migration

  def change do
    create table(:workout_logs) do
      add :date, :date, null: false
      add :exercise, :string, null: false
      add :weight, :float, null: false # Weight in kg

      timestamps()
    end

    # Ensure unique constraint on date and exercise to avoid duplicates
    create unique_index(:workout_logs, [:date, :exercise])
  end
end
