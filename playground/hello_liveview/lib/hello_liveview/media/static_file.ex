defmodule HelloLiveview.Media.StaticFile do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "static_files" do
    field :original_name, :string
    field :stored_name, :string
    field :path, :string
    field :mime_type, :string

    belongs_to :user, HelloLiveview.Accounts.User

    timestamps(type: :utc_datetime)
  end

  def changeset(static_file, attrs) do
    static_file
    |> cast(attrs, [:original_name, :stored_name, :path, :mime_type, :user_id])
    |> validate_required([:original_name, :stored_name, :path, :mime_type, :user_id])
    |> unique_constraint(:stored_name)
  end
end
