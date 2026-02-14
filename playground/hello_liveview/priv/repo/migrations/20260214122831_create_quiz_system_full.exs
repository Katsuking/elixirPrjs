defmodule HelloLiveview.Repo.Migrations.CreateQuizSystemFull do
use Ecto.Migration

  def change do
    # --- ENUM 型の作成 (テーブル作成前に必要) ---
    # 公開ステータス
    execute "CREATE TYPE quiz_status AS ENUM ('DRAFT', 'PUBLIC', 'PRIVATE')"
    # 問題の種類
    execute "CREATE TYPE question_type AS ENUM ('SINGLE_CHOICE', 'MULTIPLE_CHOICE', 'DESCRIPTIVE')"

    # --- QuizSet (問題集) ---
    create table(:quiz_sets, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :title, :string, null: false
      add :description, :text
      add :status, :quiz_status, default: "DRAFT", null: false
      add :author_id, references(:users, type: :binary_id, on_delete: :nilify_all)

      timestamps(type: :utc_datetime)
    end

    # --- Question (問題) ---
    create table(:questions, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :text, :text, null: false
      add :explanation, :text
      add :position, :integer, default: 0, null: false
      add :type, :question_type, default: "SINGLE_CHOICE", null: false # e.g. 記述式、選択式

      add :quiz_set_id, references(:quiz_sets, type: :binary_id, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    # --- Option (選択肢) ---
    create table(:options, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :text, :string, null: false
      add :is_correct, :boolean, default: false, null: false
      add :position, :integer, default: 0, null: false
      add :question_id, references(:questions, type: :binary_id, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    # --- 多対多リレーション (画像) ---
    # 問題文用
    create table(:question_images, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :question_id, references(:questions, type: :binary_id, on_delete: :delete_all), null: false
      add :static_file_id, references(:static_files, type: :binary_id, on_delete: :delete_all), null: false
      add :position, :integer, default: 0, null: false
    end

    # 解説文用
    create table(:question_explanation_images, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :question_id, references(:questions, type: :binary_id, on_delete: :delete_all), null: false
      add :static_file_id, references(:static_files, type: :binary_id, on_delete: :delete_all), null: false
      add :position, :integer, default: 0, null: false
    end

    # --- インデックス設定 ---
    create index(:quiz_sets, [:author_id])
    create index(:questions, [:quiz_set_id, :position])
    create index(:options, [:question_id, :position])
    create index(:question_images, [:question_id])
    create index(:question_explanation_images, [:question_id])
  end
end
