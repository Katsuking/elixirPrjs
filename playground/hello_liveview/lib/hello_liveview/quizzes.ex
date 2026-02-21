defmodule HelloLiveview.Quizzes do
  @moduledoc """
  The Quizzes context.
  """

  import Ecto.Query, warn: false
  alias HelloLiveview.Repo

  alias HelloLiveview.Quiz.{QuizSet, Question, Option, QuizAttempt, UserAnswer}

  @doc """
  Returns the list of quiz_sets.
  """
  def list_quiz_sets do
    Repo.all(QuizSet)
  end

  @doc """
  Gets a single quiz_set with its questions and options.
  Raises `Ecto.NoResultsError` if the Quiz set does not exist.
  """
  def get_quiz_set_with_questions!(id) do
    options_query = from o in Option, order_by: o.position
    questions_query = from q in Question, order_by: q.position, preload: [options: ^options_query]

    Repo.get!(QuizSet, id)
    |> Repo.preload(questions: questions_query)
  end

  @doc """
  Creates a new quiz attempt for a user and quiz set.
  """
  def create_quiz_attempt(attrs \\ %{}) do
    %QuizAttempt{}
    |> QuizAttempt.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Gets a quiz attempt by ID.
  """
  def get_quiz_attempt!(id), do: Repo.get!(QuizAttempt, id)

  @doc """
  Creates a user answer for a specific question within an attempt.
  If an answer already exists for this attempt/question, it updates it.
  """
  def save_user_answer(attempt_id, question_id, option_id) do
    case Repo.get_by(UserAnswer, attempt_id: attempt_id, question_id: question_id) do
      nil ->
        %UserAnswer{}
        |> UserAnswer.changeset(%{
          attempt_id: attempt_id,
          question_id: question_id,
          option_id: option_id
        })
        |> Repo.insert()

      existing_answer ->
        existing_answer
        |> UserAnswer.changeset(%{option_id: option_id})
        |> Repo.update()
    end
  end

  @doc """
  Completes a quiz attempt by calculating the score and setting the completed_at timestamp.
  """
  def complete_quiz_attempt(%QuizAttempt{} = attempt) do
    import Ecto.Query

    # Calculate score by joining user_answers with correct options
    score =
      from(ua in UserAnswer,
        join: o in Option, on: ua.option_id == o.id,
        where: ua.attempt_id == ^attempt.id and o.is_correct == true,
        select: count(ua.id)
      )
      |> Repo.one()

    attempt
    |> Ecto.Changeset.change(%{
      score: score,
      completed_at: DateTime.utc_now() |> DateTime.truncate(:second)
    })
    |> Repo.update()
  end

  @doc """
  Returns recent quiz attempts for a user.
  """
  def list_recent_user_attempts(user_id, limit \\ 5) do
    import Ecto.Query

    from(a in QuizAttempt,
      where: a.user_id == ^user_id,
      where: not is_nil(a.completed_at),
      order_by: [desc: a.completed_at],
      limit: ^limit,
      preload: [:quiz_set]
    )
    |> Repo.all()
  end
end
