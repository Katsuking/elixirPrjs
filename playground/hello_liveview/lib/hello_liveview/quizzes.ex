defmodule HelloLiveview.Quizzes do
  @moduledoc """
  The Quizzes context.
  """

  import Ecto.Query, warn: false
  alias HelloLiveview.Repo

  alias HelloLiveview.Quiz.{QuizSet, Question, Option}

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
end
