defmodule Diary.WorkoutMaster do
  @moduledoc """
  Loads and parses the workout_master.json file.
  Provides access to exercises, target muscle ratios, and muscle groups.
  """

  # Path to the JSON configuration file
  @external_resource json_path = Path.join([__DIR__, "../../config/workout_master.json"])
  @master Jason.decode!(File.read!(json_path))

  @doc """
  Returns a list of all exercise names defined in the master file.
  """
  def exercises do
    Map.keys(@master["exercises"])
  end

  @doc """
  Returns the target muscle groups and their ratios for a specific exercise.
  """
  def exercise_ratios(exercise) do
    case Map.get(@master["exercises"], exercise) do
      nil -> []
      ratios ->
        # Convert keys in the map to atoms for easier handling in Elixir
        Enum.map(ratios, fn item ->
          %{
            general: item["general"],
            detailed: item["detailed"],
            ratio: item["ratio"]
          }
        end)
    end
  end

  @doc """
  Returns a map of general muscle groups to their detailed parts.
  """
  def muscle_groups do
    @master["muscle_groups"]
  end
end
