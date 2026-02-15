
# PostgresのENUM型をElixir側で安全に扱うための専用のモジュール
defmodule HelloLiveview.Enums.QuizStatus do
  use Ecto.Type
  @values [:DRAFT, :PUBLIC, :PRIVATE]

  def type, do: :quiz_status
  def cast(value) when value in ["DRAFT", "PUBLIC", "PRIVATE"], do: {:ok, String.to_existing_atom(value)}
  def cast(value) when value in @values, do: {:ok, value}
  def cast(_), do: :error

  def load(value), do: {:ok, String.to_existing_atom(value)}
  def dump(value) when value in @values, do: {:ok, Atom.to_string(value)}
  def dump(_), do: :error

  # 表示用のutil
  def label(:DRAFT), do: "下書き"
  def label(:PUBLIC), do: "公開中"
  def label(:PRIVATE), do: "非公開"

  def values, do: @values

  def publishable?(status), do: status not in [:PUBLIC]
end
