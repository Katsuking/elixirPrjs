defmodule Diary.Notebook do
  @moduledoc """
  The Notebook context for managing diary items.
  """
  import Ecto.Query, warn: false
  alias Diary.Repo
  alias Diary.DiaryItem
  alias Diary.WorkoutLog
  alias Diary.WorkoutMaster

  @doc """
  Returns the list of diary items for a specific date, ordered by position and insertion time.
  """
  def list_diary_items(date) do
    # Fetch diary items for the given date, ordered by position and creation time
    DiaryItem
    |> where(date: ^date)
    |> order_by([di], asc: di.position, asc: di.inserted_at)
    |> Repo.all()
  end

  @doc """
  Gets a single diary item.
  """
  def get_diary_item!(id), do: Repo.get!(DiaryItem, id)

  @doc """
  Creates a diary item. If position is not specified, it is automatically
  calculated as the next available position for the given date.
  """
  def create_diary_item(attrs \\ %{}) do
    # Wrap in transaction to safely calculate position and insert the new item
    Repo.transaction(fn ->
      # If position is not provided, find the max position for the date and add 1
      attrs =
        case attrs do
          %{"date" => _date, "position" => _} -> attrs
          %{"date" => date} ->
            max_pos = get_max_position(date)
            Map.put(attrs, "position", max_pos + 1)
          _ -> attrs
        end

      %DiaryItem{}
      |> DiaryItem.changeset(attrs)
      |> Repo.insert()
    end)
    # Return the expected {:ok, struct} or {:error, changeset} format
    |> case do
      {:ok, {:ok, diary_item}} -> {:ok, diary_item}
      {:ok, {:error, changeset}} -> {:error, changeset}
      {:error, reason} -> {:error, reason}
    end
    # Broadcast the change event to PubSub
    |> broadcast_change(:diary_item_created)
  end

  @doc """
  Updates a diary item.
  """
  def update_diary_item(%DiaryItem{} = diary_item, attrs) do
    diary_item
    |> DiaryItem.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a diary item.
  """
  def delete_diary_item(%DiaryItem{} = diary_item) do
    Repo.delete(diary_item)
    # Broadcast the deletion event to PubSub
    |> broadcast_change(:diary_item_deleted)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking diary item changes.
  """
  def change_diary_item(%DiaryItem{} = diary_item, attrs \\ %{}) do
    DiaryItem.changeset(diary_item, attrs)
  end

  @doc """
  Returns a MapSet of dates with diary entries for a given date range.
  """
  def list_calendar_data(start_date, end_date) do
    # Fetch distinct dates that have diary items within the date range
    from(di in DiaryItem,
      where: di.date >= ^start_date and di.date <= ^end_date,
      select: di.date,
      distinct: true
    )
    |> Repo.all()
    # Convert the list of dates into a MapSet for O(1) lookup
    |> MapSet.new()
  end

  # Helper inside Diary.Notebook to broadcast database changes
  defp broadcast_change({:ok, item} = result, event) do
    Phoenix.PubSub.broadcast(Diary.PubSub, "diary:#{item.date}", {event, item})
    result
  end
  defp broadcast_change(error_or_other, _event), do: error_or_other

  # Helper function to get the maximum position of items for a specific date.
  # Returns 0 if no items exist.
  defp get_max_position(date) do
    # Parse date if it's passed as a string
    parsed_date =
      case date do
        %Date{} -> date # 1. If 'date' is already a %Date{} struct, return it as is
        str when is_binary(str) -> Date.from_iso8601!(str) # 2. If 'date' is a binary string (like "2024-12-25"), convert it to a %Date{} struct using Date.from_iso8601!/1.
        _ -> nil # 3. For any other case, return nil
      end

    if parsed_date do
      # Query the max position from the DB
      query = from(di in DiaryItem, where: di.date == ^parsed_date, select: max(di.position))
      Repo.one(query) || 0
    else
      0
    end
  end

  @doc """
  Returns all workout logs for a given date.
  """
  def list_workout_logs(date) do
    WorkoutLog
    |> where(date: ^date)
    |> order_by(asc: :id)
    |> Repo.all()
  end

  @doc """
  Saves a set log for a given date, exercise, weight, and reps.
  """
  def save_workout_log(date, exercise, weight, reps) do
    reps_val = (reps || 0) |> to_int()
    weight_val = (weight || 0.0) |> to_float()

    params = %{date: date, exercise: exercise, weight: weight_val, reps: reps_val}

    %WorkoutLog{}
    |> WorkoutLog.changeset(params)
    |> Repo.insert()
    |> case do
      {:ok, log} ->
        Phoenix.PubSub.broadcast(Diary.PubSub, "diary:#{date}", {:workout_log_updated, date})
        {:ok, log}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  @doc """
  Deletes a workout log entry by id.
  """
  def delete_workout_log(id) do
    case Repo.get(WorkoutLog, id) do
      nil -> {:ok, nil}
      log ->
        date = log.date
        Repo.delete!(log)
        Phoenix.PubSub.broadcast(Diary.PubSub, "diary:#{date}", {:workout_log_updated, date})
        {:ok, log}
    end
  end

  @doc """
  Calculates the total training volume (weight * reps) for a given date.
  """
  def get_workout_volume_for_date(date) do
    list_workout_logs(date)
    |> Enum.reduce(0.0, fn log, acc ->
      acc + (log.weight * log.reps)
    end)
  end

  defp to_int(val) when is_integer(val), do: val
  defp to_int(val) when is_binary(val) do
    case Integer.parse(val) do
      {i, _} -> i
      _ -> 0
    end
  end
  defp to_int(_), do: 0

  defp to_float(val) when is_float(val), do: val
  defp to_float(val) when is_integer(val), do: val * 1.0
  defp to_float(val) when is_binary(val) do
    case Float.parse(val) do
      {f, _} -> f
      _ -> 0.0
    end
  end
  defp to_float(_), do: 0.0

  @doc """
  Returns all workout logs in a given date range.
  """
  def list_workout_logs_in_range(start_date, end_date) do
    WorkoutLog
    |> where([wl], wl.date >= ^start_date and wl.date <= ^end_date)
    |> Repo.all()
  end

  @doc """
  Aggregates workout training volume (weight * reps) into general and detailed muscle groups.
  """
  def aggregate_workout_weights(workout_logs) do
    initial_state = %{general: %{}, detailed: %{}}

    Enum.reduce(workout_logs, initial_state, fn log, acc ->
      exercise = log.exercise
      log_volume = (log.weight || 0.0) * (log.reps || 0)
      ratios = WorkoutMaster.exercise_ratios(exercise)

      Enum.reduce(ratios, acc, fn ratio_item, acc_inner ->
        general_group = ratio_item.general
        detailed_part = ratio_item.detailed
        distributed_volume = log_volume * ratio_item.ratio

        # 1. Update general totals
        new_general = Map.update(acc_inner.general, general_group, distributed_volume, &(&1 + distributed_volume))

        # 2. Update detailed totals
        new_detailed =
          Map.update(acc_inner.detailed, general_group, %{detailed_part => distributed_volume}, fn detailed_map ->
            Map.update(detailed_map, detailed_part, distributed_volume, &(&1 + distributed_volume))
          end)

        %{general: new_general, detailed: new_detailed}
      end)
    end)
  end

  @doc """
  Fetches and aggregates weekly, monthly, and yearly workout logs relative to a given date.
  """
  def get_workout_stats(date) do
    # Daily range
    daily_logs = list_workout_logs(date)

    # Weekly range (beginning to end of week)
    weekly_start = Date.beginning_of_week(date)
    weekly_end = Date.end_of_week(date)
    weekly_logs = list_workout_logs_in_range(weekly_start, weekly_end)

    # Monthly range
    monthly_start = Date.beginning_of_month(date)
    monthly_end = Date.end_of_month(date)
    monthly_logs = list_workout_logs_in_range(monthly_start, monthly_end)

    # Yearly range
    yearly_start = Date.new!(date.year, 1, 1)
    yearly_end = Date.new!(date.year, 12, 31)
    yearly_logs = list_workout_logs_in_range(yearly_start, yearly_end)

    %{
      daily: aggregate_workout_weights(daily_logs),
      weekly: aggregate_workout_weights(weekly_logs),
      monthly: aggregate_workout_weights(monthly_logs),
      yearly: aggregate_workout_weights(yearly_logs)
    }
  end
end
