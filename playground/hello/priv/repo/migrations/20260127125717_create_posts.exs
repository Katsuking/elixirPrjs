defmodule Hello.Repo.Migrations.CreatePosts do
  use Ecto.Migration

  def change do
    create table(:posts) do
      add :title, :string
      add :body, :text

      timestamps() # inserted_at と updated_at が自動追加されます
    end
  end
end
