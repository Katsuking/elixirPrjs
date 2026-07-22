defmodule Diary.WorkoutLog do
  @moduledoc """
  Schema definition for a single exercise set log.
  """
  use Ecto.Schema
  import Ecto.Changeset

  schema "workout_logs" do
    field :date, :date
    field :exercise, :string
    field :weight, :float # Weight in kg
    field :reps, :integer, default: 0

    timestamps()
  end

  @doc """
  Generates a changeset for validating and storing a single set log.
  """
  def changeset(workout_log, attrs) do
    workout_log
    |> cast(attrs, [:date, :exercise, :weight, :reps])
    |> validate_required([:date, :exercise, :weight, :reps])
    |> validate_number(:weight, greater_than_or_equal_to: 0.0)
    |> validate_number(:reps, greater_than: 0)
  end
end
