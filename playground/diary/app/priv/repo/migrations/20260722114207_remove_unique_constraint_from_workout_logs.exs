defmodule Diary.Repo.Migrations.RemoveUniqueConstraintFromWorkoutLogs do
  use Ecto.Migration

  def change do
    # Drop the unique index to allow multiple entries of the same exercise on the same day
    drop unique_index(:workout_logs, [:date, :exercise])

    # Add a non-unique index to maintain query performance
    create index(:workout_logs, [:date, :exercise])
  end
end
