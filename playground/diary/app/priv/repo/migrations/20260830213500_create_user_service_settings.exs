defmodule Diary.Repo.Migrations.CreateUserServiceSettings do
  @moduledoc """
  Migration to create user_service_settings table for storing per-service permissions and location data.
  """
  use Ecto.Migration

  def change do
    create table(:user_service_settings) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :service_name, :string, null: false
      add :location_enabled, :boolean, default: false, null: false
      add :latitude, :decimal
      add :longitude, :decimal
      add :accuracy, :integer

      timestamps(type: :utc_datetime)
    end

    # Composite unique index to ensure one setting per user per service
    create unique_index(:user_service_settings, [:user_id, :service_name])
  end
end
