defmodule HelloLiveview.Quiz.QuizSet do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "quiz_sets" do
    field :title, :string
    field :description, :string
    field :status, HelloLiveview.Enums.QuizStatus, default: :DRAFT

    belongs_to :author, HelloLiveview.Accounts.User
    has_many :questions, HelloLiveview.Quiz.Question, on_replace: :delete

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(quiz_set, attrs) do
    quiz_set
    |> cast(attrs, [:title, :description, :status, :author_id])
    |> validate_required([:title, :status])
  end
end
