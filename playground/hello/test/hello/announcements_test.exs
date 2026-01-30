defmodule Hello.AnnouncementsTest do
  use Hello.DataCase

  alias Hello.Announcements

  describe "notices" do
    alias Hello.Announcements.Notice

    import Hello.AnnouncementsFixtures

    @invalid_attrs %{title: nil, content: nil, published_at: nil}

    test "list_notices/0 returns all notices" do
      notice = notice_fixture()
      assert Announcements.list_notices() == [notice]
    end

    test "get_notice!/1 returns the notice with given id" do
      notice = notice_fixture()
      assert Announcements.get_notice!(notice.id) == notice
    end

    test "create_notice/1 with valid data creates a notice" do
      valid_attrs = %{title: "some title", content: "some content", published_at: ~U[2026-01-27 12:12:00Z]}

      assert {:ok, %Notice{} = notice} = Announcements.create_notice(valid_attrs)
      assert notice.title == "some title"
      assert notice.content == "some content"
      assert notice.published_at == ~U[2026-01-27 12:12:00Z]
    end

    test "create_notice/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Announcements.create_notice(@invalid_attrs)
    end

    test "update_notice/2 with valid data updates the notice" do
      notice = notice_fixture()
      update_attrs = %{title: "some updated title", content: "some updated content", published_at: ~U[2026-01-28 12:12:00Z]}

      assert {:ok, %Notice{} = notice} = Announcements.update_notice(notice, update_attrs)
      assert notice.title == "some updated title"
      assert notice.content == "some updated content"
      assert notice.published_at == ~U[2026-01-28 12:12:00Z]
    end

    test "update_notice/2 with invalid data returns error changeset" do
      notice = notice_fixture()
      assert {:error, %Ecto.Changeset{}} = Announcements.update_notice(notice, @invalid_attrs)
      assert notice == Announcements.get_notice!(notice.id)
    end

    test "delete_notice/1 deletes the notice" do
      notice = notice_fixture()
      assert {:ok, %Notice{}} = Announcements.delete_notice(notice)
      assert_raise Ecto.NoResultsError, fn -> Announcements.get_notice!(notice.id) end
    end

    test "change_notice/1 returns a notice changeset" do
      notice = notice_fixture()
      assert %Ecto.Changeset{} = Announcements.change_notice(notice)
    end
  end
end
