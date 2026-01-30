defmodule Hello.Repo.Migrations.CreateNotices do
  use Ecto.Migration

  def change do
    create table(:notices, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :title, :string
      add :content, :text
      add :published_at, :utc_datetime

      timestamps(type: :utc_datetime)
    end
  end
end
