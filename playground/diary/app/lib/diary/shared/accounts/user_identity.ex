defmodule Diary.Accounts.UserIdentity do
  use Ecto.Schema
  import Ecto.Changeset

  schema "user_identities" do
    field :provider, :string
    field :uid, :string
    belongs_to :user, Diary.Accounts.User

    timestamps()
  end

  @doc """
  Builds a changeset for UserIdentity.
  """
  def changeset(user_identity, attrs) do
    user_identity
    |> cast(attrs, [:provider, :uid, :user_id])
    |> validate_required([:provider, :uid, :user_id])
    |> foreign_key_constraint(:user_id)
    |> unique_constraint([:provider, :uid])
  end
end
