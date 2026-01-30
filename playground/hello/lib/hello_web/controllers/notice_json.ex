defmodule HelloWeb.NoticeJSON do
  alias Hello.Announcements.Notice

  @doc """
  Renders a list of notices.
  """
  def index(%{notices: notices}) do
    %{data: for(notice <- notices, do: data(notice))}
  end

  @doc """
  Renders a single notice.
  """
  def show(%{notice: notice}) do
    %{data: data(notice)}
  end

  defp data(%Notice{} = notice) do
    %{
      id: notice.id,
      title: notice.title,
      content: notice.content,
      published_at: notice.published_at
    }
  end
end
