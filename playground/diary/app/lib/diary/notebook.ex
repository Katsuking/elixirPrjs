defmodule Diary.Notebook do
  @moduledoc """
  The Notebook context for managing diary items.
  """
  import Ecto.Query, warn: false
  alias Diary.Repo
  alias Diary.DiaryItem

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
          %{"date" => date, "position" => _} -> attrs
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
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking diary item changes.
  """
  def change_diary_item(%DiaryItem{} = diary_item, attrs \\ %{}) do
    DiaryItem.changeset(diary_item, attrs)
  end

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
end
