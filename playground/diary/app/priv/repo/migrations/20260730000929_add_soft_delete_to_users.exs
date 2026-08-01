defmodule Diary.Repo.Migrations.AddSoftDeleteToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :deleted_at, :utc_datetime
    end

    drop unique_index(:users, [:email])
    create unique_index(:users, [:email], where: "deleted_at IS NULL")
  end
end
