defmodule Diary.WorkoutLog do
  @moduledoc """
  Schema definition for a single exercise workout log.
  """
  use Ecto.Schema
  import Ecto.Changeset

  schema "workout_logs" do
    field :date, :date
    field :exercise, :string
    field :weight, :float # Weight in kg

    timestamps()
  end

  @doc """
  Generates a changeset for validating and storing a workout log.
  """
  def changeset(workout_log, attrs) do
    workout_log
    |> cast(attrs, [:date, :exercise, :weight])
    |> validate_required([:date, :exercise, :weight])
    |> validate_number(:weight, greater_than_or_equal_to: 0.0)
    |> unique_constraint([:date, :exercise])
  end
end
