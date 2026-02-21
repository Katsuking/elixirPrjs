defmodule HelloLiveview.Quiz.UserAnswer do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "user_answers" do
    belongs_to :attempt, HelloLiveview.Quiz.QuizAttempt
    belongs_to :question, HelloLiveview.Quiz.Question
    belongs_to :option, HelloLiveview.Quiz.Option

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(user_answer, attrs) do
    user_answer
    |> cast(attrs, [:attempt_id, :question_id, :option_id])
    |> validate_required([:attempt_id, :question_id])
    |> unique_constraint([:attempt_id, :question_id])
  end
end
