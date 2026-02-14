defmodule HelloLiveview.Accounts.UserProfile do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "user_profiles" do
    field :name, :string
    field :class, Ecto.Enum, values: [:STUDENT, :FREE, :PREMIUM], default: :STUDENT
    field :provider, :string
    field :provider_id, :string
    field :picture, :string

    belongs_to :user, HelloLiveview.Accounts.User
    belongs_to :avatar, HelloLiveview.Media.StaticFile, foreign_key: :avatar_image_id

    timestamps(type: :utc_datetime)
  end

  def changeset(user_profile, attrs) do
    user_profile
    |> cast(attrs, [:name, :class, :provider, :provider_id, :picture, :user_id, :avatar_image_id])
    |> validate_required([:name, :user_id])
    |> unique_constraint(:user_id)
    |> unsafe_validate_unique(:name, HelloLiveview.Repo)
    |> unique_constraint(:name, mesage: "このユーザー名はすでに使用されています")
  end

end
