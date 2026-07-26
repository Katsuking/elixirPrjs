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

  @doc """
  Exports daily activity summary (workout volume, exercises, and diary items) as a CSV file.
  """
  def export_daily_summary(conn, _params) do
    user_id = conn.assigns.current_scope.user.id
    
    # Retrieve all logs and diary items
    logs = Notebook.list_all_workout_logs(user_id)
    diary_items = Notebook.list_all_diary_items(user_id)

    # Extract and merge unique dates, then sort them chronologically
    log_dates = Enum.map(logs, & &1.date)
    diary_dates = Enum.map(diary_items, & &1.date)
    
    all_dates = 
      (log_dates ++ diary_dates)
      |> Enum.uniq()
      |> Enum.sort(Date)

    # Group by date for efficient O(1) lookups
    logs_by_date = Enum.group_by(logs, & &1.date)
    diary_by_date = Enum.group_by(diary_items, & &1.date)

    csv_data = generate_daily_summary_csv(all_dates, logs_by_date, diary_by_date)

    conn
    |> put_resp_content_type("text/csv")
    |> put_resp_header("content-disposition", "attachment; filename=\"daily_activity_summary.csv\"")
    |> send_resp(200, csv_data)
  end

  # Helper to format daily activity summary data into CSV
  defp generate_daily_summary_csv(dates, logs_by_date, diary_by_date) do
    # Column Header row
    header = "Date,Total Workout Volume (kg),Exercises Done,Diary Items\n"

    body =
      dates
      |> Enum.map(fn date ->
        day_logs = Map.get(logs_by_date, date, [])
        day_diary = Map.get(diary_by_date, date, [])

        # 1. Calculate total volume for the day (weight * reps)
        total_volume =
          day_logs
          |> Enum.reduce(0.0, fn log, acc -> acc + (log.weight * log.reps) end)

        # 2. Format exercises done with sets count
        exercises_str =
          if day_logs == [] do
            "None"
          else
            day_logs
            # Group logs of the day by exercise name to count sets
            |> Enum.group_by(& &1.exercise)
            |> Enum.map(fn {exercise, list} ->
              "#{exercise} (#{length(list)} sets)"
            end)
            |> Enum.join(" | ")
          end

        # 3. Format diary items
        diary_str =
          day_diary
          |> Enum.map(& &1.content)
          |> Enum.join(" | ")

        "#{date},#{total_volume},\"#{escape_csv(exercises_str)}\",\"#{escape_csv(diary_str)}\""
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
