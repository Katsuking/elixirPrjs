# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs

alias HelloLiveview.Repo
alias HelloLiveview.Quiz.{QuizSet, Question, Option}

# 既存のデータを削除（クリーンな状態にする場合）
# Repo.delete_all(Option)
# Repo.delete_all(Question)
# Repo.delete_all(QuizSet)

quiz_set = Repo.insert!(%QuizSet{
  title: "Elixir & Phoenix 基礎クイズ",
  description: "Elixirの構文やPhoenix LiveViewの基本概念に関する問題集です。",
  status: :PUBLIC
})

q1 = Repo.insert!(%Question{
  text: "Elixirでパターンマッチを行うための主要な演算子はどれですか？",
  explanation: "Elixirでは = 演算子を使用してパターンマッチを行います。これは単なる代入ではなく、左辺と右辺を一致させる試みです。",
  position: 0,
  type: :SINGLE_CHOICE,
  quiz_set_id: quiz_set.id
})

Repo.insert!(%Option{text: "== 演算子", is_correct: false, position: 0, question_id: q1.id})
Repo.insert!(%Option{text: "= 演算子", is_correct: true, position: 1, question_id: q1.id})
Repo.insert!(%Option{text: "def キーワード", is_correct: false, position: 2, question_id: q1.id})
Repo.insert!(%Option{text: "match? 関数", is_correct: false, position: 3, question_id: q1.id})

q2 = Repo.insert!(%Question{
  text: "Phoenix LiveViewについて正しい説明はどれですか？",
  explanation: "LiveViewはサーバー側で状態を保持し、WebSocketを通じて差分データのみをクライアントに送信することで、高速かつインタラクティブなUIを実現します。",
  position: 1,
  type: :SINGLE_CHOICE,
  quiz_set_id: quiz_set.id
})

Repo.insert!(%Option{text: "WebAssemblyを使用してブラウザ上でのみ動作する", is_correct: false, position: 0, question_id: q2.id})
Repo.insert!(%Option{text: "サーバーで状態を管理し、WebSocket経由でHTMLの差分を送信する", is_correct: true, position: 1, question_id: q2.id})
Repo.insert!(%Option{text: "PostgreSQLデータベースをインメモリデータストアに置き換える", is_correct: false, position: 2, question_id: q2.id})
Repo.insert!(%Option{text: "Reactのフロントエンドコードを自動生成する", is_correct: false, position: 3, question_id: q2.id})

IO.puts("Successfully seeded database with quiz_set ID: #{quiz_set.id}")
