defmodule Diary.Mood do
  use Ecto.Schema
  import Ecto.Changeset

  schema "moods" do
    field :date, :date
    field :status, :string

    timestamps()
  end

  def changeset(mood, attrs) do
    mood
    |> cast(attrs, [:date, :status])
    |> validate_required([:date, :status])
    |> validate_inclusion(:status, ["good", "very good", "beast", "on fire", "disciplined"])
    |> unique_constraint(:date)
  end

end
