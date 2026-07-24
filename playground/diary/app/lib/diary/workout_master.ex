defmodule Diary.WorkoutMaster do
  @moduledoc """
  Loads and parses the workout_master.json file.
  Provides access to exercises, target muscle ratios, and muscle groups.
  """
  use Gettext, backend: DiaryWeb.Gettext

  # Dummy function for gettext static extraction
  def dummy_translations do
    # Muscle Groups
    gettext("胸")
    gettext("背中")
    gettext("肩")
    gettext("脚")
    gettext("腕")
    gettext("腹")

    # Detailed parts
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

    # Detailed parts / sub-groups for Arms (Added for dynamic grouping)
    gettext("二頭筋")
    gettext("三頭筋")
    gettext("前腕")

    # Training systems for Abs
    gettext("クランチ系")
    gettext("シットアップ系")
    gettext("レッグレイズ系")
    gettext("ハンギング系")
    gettext("プランク系")
    gettext("ツイスト・腹斜筋系")
    gettext("ロールアウト系")
    gettext("体幹・スタビリティ系")

    # Exercise names (Added for i18n support)
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
    gettext("バーベルカール")
    gettext("ダンベルカール")
    gettext("ハンマーカール")
    gettext("プリーチャーカール")
    gettext("ケーブルカール")
    gettext("プレスダウン")
    gettext("ローププレスダウン")
    gettext("スカルクラッシャー")
    gettext("オーバーヘッドエクステンション")
    gettext("キックバック")
    gettext("リストカール")
    gettext("リバースリストカール")
    gettext("ハンドグリッパー")
    gettext("クランチ")
    gettext("シットアップ")
    gettext("レッグレイズ")
    gettext("ハンギングレッグレイズ")
    gettext("プランク")
    gettext("ロシアツイスト")
    gettext("アブローラー")
    gettext("バードドッグ")
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
