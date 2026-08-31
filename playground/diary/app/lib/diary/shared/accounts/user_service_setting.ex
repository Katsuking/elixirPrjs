defmodule Diary.Accounts.UserServiceSetting do
  @moduledoc """
  Schema representing user settings and location permissions on a per-service basis (e.g. "gym", "map").
  """
  use Ecto.Schema
  import Ecto.Changeset

  schema "user_service_settings" do
    field :service_name, :string
    field :location_enabled, :boolean, default: false
    field :latitude, :decimal
    field :longitude, :decimal
    field :accuracy, :integer

    belongs_to :user, Diary.Accounts.User

    timestamps(type: :utc_datetime)
  end

  @doc """
  Changeset for user_service_setting attributes.
  """
  def changeset(setting, attrs) do
    setting
    |> cast(attrs, [:user_id, :service_name, :location_enabled, :latitude, :longitude, :accuracy])
    |> validate_required([:user_id, :service_name])
    |> unique_constraint([:user_id, :service_name], name: :user_service_settings_user_id_service_name_index)
  end
end
