defmodule HelloLiveview.Quiz.Question do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "questions" do
    field :text, :string
    field :explanation, :string
    field :position, :integer, default: 0
    field :type, HelloLiveview.Enums.QuestionType, default: :SINGLE_CHOICE

    belongs_to :quiz_set, HelloLiveview.Quiz.QuizSet
    has_many :options, HelloLiveview.Quiz.Option, on_replace: :delete

    timestamps(type: :utc_datetime)
  end

  def changeset(question, attrs) do
    question
    |> cast(attrs, [:text, :explanation, :position, :type, :quiz_set_id])
    |> validate_required([:text, :type, :quiz_set_id])
    |> cast_assoc(:options)
  end
end
