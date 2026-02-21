defmodule HelloLiveview.Quiz.Option do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "options" do
    field :text, :string
    field :is_correct, :boolean, default: false
    field :position, :integer, default: 0

    belongs_to :question, HelloLiveview.Quiz.Question

    timestamps(type: :utc_datetime)
  end

  def changeset(option, attrs) do
    option
    |> cast(attrs, [:text, :is_correct, :position, :question_id])
    |> validate_required([:text, :is_correct, :question_id])
  end
end
