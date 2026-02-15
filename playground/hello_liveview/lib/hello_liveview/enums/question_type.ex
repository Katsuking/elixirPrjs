defmodule HelloLiveview.Enums.QuestionType do
  use Ecto.Type

  # マイグレーションで定義したENUM値と一致させる
  @values [:SINGLE_CHOICE, :MULTIPLE_CHOICE, :DESCRIPTIVE]

  def type, do: :question_type

  # DBからの読み込み 文字列 -> アトム
  def cast(value) when value in ["SINGLE_CHOICE", "MULTIPLE_CHOICE", "DESCRIPTIVE"],
    do: {:ok, String.to_existing_atom(value)}
  def cast(value) when value in @values, do: {:ok, value}
  def cast(_), do: :error

  def load(value), do: {:ok, String.to_existing_atom(value)}

  # DBへの書き込み アトム -> 文字列
  def dump(value) when value in @values, do: {:ok, Atom.to_string(value)}
  def dump(_), do: :error

  # Phoenixのセレクトボックスなどで使うためのヘルパー
  def values, do: @values
end
