defmodule Diary.Repo.Migrations.AddUserIdToExistingTables do
  use Ecto.Migration

  def change do
    # Add user_id column referencing users table to diary_items
    alter table(:diary_items) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
    end

    # Add user_id column referencing users table to workout_logs
    alter table(:workout_logs) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
    end

    # Create indexes for foreign keys
    create index(:diary_items, [:user_id])
    create index(:workout_logs, [:user_id])
  end
end
