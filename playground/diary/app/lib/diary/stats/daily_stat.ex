defmodule Diary.Stats.DailyStat do
  use Ecto.Schema
  import Ecto.Changeset

  schema "daily_stats" do
    field :date, :date
    field :user_count, :integer

    timestamps(type: :utc_datetime)
  end

  @doc """
  Builds a changeset for daily statistics.
  """
  def changeset(daily_stat, attrs) do
    daily_stat
    |> cast(attrs, [:date, :user_count])
    |> validate_required([:date, :user_count])
    |> unique_constraint(:date)
  end
end
