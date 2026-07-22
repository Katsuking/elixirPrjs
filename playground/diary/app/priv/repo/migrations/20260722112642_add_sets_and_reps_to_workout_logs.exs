defmodule Diary.Repo.Migrations.AddSetsAndRepsToWorkoutLogs do
  use Ecto.Migration

  def change do
    alter table(:workout_logs) do
      add :sets, :integer, default: 0
      add :reps, :integer, default: 0
    end
  end
end
