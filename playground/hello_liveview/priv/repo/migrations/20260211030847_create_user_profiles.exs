defmodule HelloLiveview.Repo.Migrations.CreateUserProfiles do
  use Ecto.Migration

  def change do
    create table(:static_files, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :original_name, :string, null: false
      add :stored_name, :string, null: false
      add :path, :string, null: false
      add :mime_type, :string, null: false
      add :user_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end
    create index(:static_files, [:user_id]) # 誰がアップロードしたファイルか検索するために必須
    create unique_index(:static_files, [:stored_name]) # ファイル名やパスで検索・重複確認

    execute "CREATE TYPE user_class AS ENUM ('STUDENT', 'FREE', 'PREMIUM')"

    create table(:user_profiles, primary_key: false) do
      add :id, :binary_id, primary_key: true
      # 本体 users テーブルへの参照 (1:1)
      add :user_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false
      add :avatar_image_id, references(:static_files, type: :binary_id, on_delete: :nilify_all)
      add :name, :string, null: false
      add :class, :user_class, default: "FREE", null: false
      add :provider, :string
      add :provider_id, :string
      add :picture, :string

      timestamps(type: :utc_datetime)
    end

    create unique_index(:user_profiles, [:user_id])
    create unique_index(:user_profiles, [:provider, :provider_id]) # provider と provider_id の組み合わせで一意にするのが一般的
  end
end
