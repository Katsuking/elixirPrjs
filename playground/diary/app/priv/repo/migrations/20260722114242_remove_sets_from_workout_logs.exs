defmodule Diary.Repo.Migrations.RemoveSetsFromWorkoutLogs do
  use Ecto.Migration

  def change do
    # Remove the sets column since each row now represents a single set
    alter table(:workout_logs) do
      remove :sets
    end
  end
end
