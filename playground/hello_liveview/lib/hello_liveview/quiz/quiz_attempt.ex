defmodule HelloLiveview.Quiz.QuizAttempt do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "quiz_attempts" do
    field :score, :integer, default: 0
    field :completed_at, :utc_datetime

    belongs_to :user, HelloLiveview.Accounts.User
    belongs_to :quiz_set, HelloLiveview.Quiz.QuizSet
    has_many :user_answers, HelloLiveview.Quiz.UserAnswer, foreign_key: :attempt_id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(quiz_attempt, attrs) do
    quiz_attempt
    |> cast(attrs, [:score, :completed_at, :user_id, :quiz_set_id])
    |> validate_required([:user_id, :quiz_set_id])
  end
end
