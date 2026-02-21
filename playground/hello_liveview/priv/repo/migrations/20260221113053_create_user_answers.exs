defmodule HelloLiveview.Repo.Migrations.CreateUserAnswers do
  use Ecto.Migration

  def change do
    create table(:user_answers, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :attempt_id, references(:quiz_attempts, on_delete: :delete_all, type: :binary_id), null: false
      add :question_id, references(:questions, on_delete: :delete_all, type: :binary_id), null: false
      add :option_id, references(:options, on_delete: :nilify_all, type: :binary_id)

      timestamps(type: :utc_datetime)
    end

    create index(:user_answers, [:attempt_id])
    create index(:user_answers, [:question_id])
    create unique_index(:user_answers, [:attempt_id, :question_id])
  end
end
