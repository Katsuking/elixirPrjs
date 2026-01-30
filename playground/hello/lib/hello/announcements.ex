defmodule Hello.Announcements do
  @moduledoc """
  The Announcements context.
  """

  import Ecto.Query, warn: false
  alias Hello.Repo

  alias Hello.Announcements.Notice

  @doc """
  Returns the list of notices.

  ## Examples

      iex> list_notices()
      [%Notice{}, ...]

  """
  def list_notices do
    Repo.all(Notice)
  end

  def list_elixir_inclued(keyword) do
    Notice
    |> where([n], ilike(n.title, ^"%#{keyword}%"))
    |> Repo.all()
  end

  @doc """
  Gets a single notice.

  Raises `Ecto.NoResultsError` if the Notice does not exist.

  ## Examples

      iex> get_notice!(123)
      %Notice{}

      iex> get_notice!(456)
      ** (Ecto.NoResultsError)

  """
  def get_notice!(id), do: Repo.get!(Notice, id)

  @doc """
  Creates a notice.

  ## Examples

      iex> create_notice(%{field: value})
      {:ok, %Notice{}}

      iex> create_notice(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_notice(attrs) do
    %Notice{}
    |> Notice.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a notice.

  ## Examples

      iex> update_notice(notice, %{field: new_value})
      {:ok, %Notice{}}

      iex> update_notice(notice, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_notice(%Notice{} = notice, attrs) do
    notice
    |> Notice.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a notice.

  ## Examples

      iex> delete_notice(notice)
      {:ok, %Notice{}}

      iex> delete_notice(notice)
      {:error, %Ecto.Changeset{}}

  """
  def delete_notice(%Notice{} = notice) do
    Repo.delete(notice)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking notice changes.

  ## Examples

      iex> change_notice(notice)
      %Ecto.Changeset{data: %Notice{}}

  """
  def change_notice(%Notice{} = notice, attrs \\ %{}) do
    Notice.changeset(notice, attrs)
  end
end
