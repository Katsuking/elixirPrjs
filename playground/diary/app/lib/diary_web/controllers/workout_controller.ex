defmodule DiaryWeb.WorkoutController do
  use DiaryWeb, :controller

  alias Diary.Notebook

  @doc """
  Exports all workout logs for the authenticated user as a CSV file download.
  """
  def export_csv(conn, _params) do
    user_id = conn.assigns.current_scope.user.id
    logs = Notebook.list_all_workout_logs(user_id)

    csv_data = generate_csv(logs)

    conn
    |> put_resp_content_type("text/csv")
    |> put_resp_header("content-disposition", "attachment; filename=\"workout_logs.csv\"")
    |> send_resp(200, csv_data)
  end

  # Generates CSV data from list of workout logs
  defp generate_csv(logs) do
    # Column Header row
    header = "Date,Exercise,Weight (kg),Reps\n"

    body =
      logs
      |> Enum.map(fn log ->
        "#{log.date},\"#{escape_csv(log.exercise)}\",#{log.weight},#{log.reps}"
      end)
      |> Enum.join("\n")

    header <> body
  end

  # Escape double quotes for valid CSV formatting
  defp escape_csv(string) when is_binary(string) do
    String.replace(string, "\"", "\"\"")
  end
  defp escape_csv(val), do: "#{val}"
end
