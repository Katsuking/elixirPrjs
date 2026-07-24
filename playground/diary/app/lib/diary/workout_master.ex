defmodule Diary.WorkoutMaster do
  @moduledoc """
  Loads and parses the workout_master.json file.
  Provides access to exercises, target muscle ratios, and muscle groups.
  """
  use Gettext, backend: DiaryWeb.Gettext

  # Dummy function for gettext static extraction
  def dummy_translations do
    gettext("胸")
    gettext("背中")
    gettext("肩")
    gettext("脚")
    gettext("腕")
    gettext("腹")

    gettext("上部")
    gettext("中部")
    gettext("下部")
    gettext("前部")
    gettext("中部（側部）")
    gettext("後部")
    gettext("広背筋")
    gettext("僧帽筋")
    gettext("脊柱起立筋")
    gettext("大腿四頭筋")
    gettext("ハムストリングス")
    gettext("臀筋")
    gettext("内転筋")
    gettext("ふくらはぎ")
    gettext("長頭")
    gettext("短頭")
    gettext("外側頭")
    gettext("内側頭")
    gettext("腹直筋")
    gettext("腹斜筋")

    gettext("ベンチプレス")
    gettext("インクラインベンチ")
    gettext("ダンベルベンチ")
    gettext("懸垂")
    gettext("ラットプルダウン")
    gettext("バーベルロー")
    gettext("ショルダープレス")
    gettext("スクワット")
    gettext("レッグプレス")
    gettext("デッドリフト")
    gettext("RDL")
    gettext("ダンベルカール")
    gettext("プレスダウン")
    gettext("クランチ")
  end

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
