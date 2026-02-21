defmodule HelloLiveview.Repo.Migrations.CreateQuizAttempts do
  use Ecto.Migration

  def change do
    create table(:quiz_attempts, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :score, :integer, default: 0, null: false
      add :completed_at, :utc_datetime

      add :user_id, references(:users, on_delete: :delete_all, type: :binary_id), null: false
      add :quiz_set_id, references(:quiz_sets, on_delete: :delete_all, type: :binary_id), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:quiz_attempts, [:user_id])
    create index(:quiz_attempts, [:quiz_set_id])
  end
end
