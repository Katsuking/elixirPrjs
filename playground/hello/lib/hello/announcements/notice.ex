defmodule Hello.Announcements.Notice do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "notices" do
    field :title, :string
    field :content, :string
    field :published_at, :utc_datetime

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(notice, attrs) do
    notice
    |> cast(attrs, [:title, :content, :published_at])
    |> validate_required([:title, :content, :published_at])
  end
end
