defmodule DiaryWeb.DiaryLiveTest do
  use DiaryWeb.ConnCase
  import Phoenix.LiveViewTest

  # Test layout and initial render of the calendar
  test "initial render shows calendar and active month", %{conn: conn} do
    {:ok, _view, html} = live(conn, ~p"/")

    # The title/headings should be present
    assert html =~ "Entries"

    # The calendar table or grid should be rendered
    assert html =~ "Sun"
    assert html =~ "Mon"

    # Check that current month is displayed (e.g. July 2026)
    today = Date.utc_today()
    assert html =~ format_month_year(today)
  end

  # Test calendar month navigation
  test "navigating months updates header", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/")

    # Navigate to the next month
    next_html = view |> element("button[phx-click='next_month']") |> render_click()
    next_month_date = shift_month(Date.utc_today(), 1)
    assert next_html =~ format_month_year(next_month_date)

    # Navigate to the previous month
    _prev_html = view |> element("button[phx-click='prev_month']") |> render_click()
    # Click prev_month twice to get to previous month from next month
    prev_html = view |> element("button[phx-click='prev_month']") |> render_click()
    prev_month_date = shift_month(Date.utc_today(), -1)
    assert prev_html =~ format_month_year(prev_month_date)
  end

  # Test selecting a date from the calendar
  test "selecting a date updates active date and diary items", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/")

    # Select a specific date (yesterday)
    yesterday = Date.add(Date.utc_today(), -1)
    yesterday_str = Date.to_iso8601(yesterday)

    # Click the calendar day button
    html = view |> element("button[phx-value-date='#{yesterday_str}']") |> render_click()

    # The active date display or path should be updated
    assert html =~ yesterday_str
  end

  # Test localization switch (Japanese locale)
  test "renders in Japanese when locale parameter is provided", %{conn: conn} do
    {:ok, _view, html} = live(conn, ~p"/?locale=ja")

    # Weekdays in Japanese
    assert html =~ "日"
    assert html =~ "月"
    assert html =~ "火"

    # Year-Month format (e.g. 2026年 7月)
    today = Date.utc_today()
    assert html =~ "#{today.year}年 #{today.month}月"
  end

  # Helper functions to format and shift month for assertions
  defp shift_month(date, offset) do
    year = date.year
    month = date.month

    {new_year, new_month} =
      case month + offset do
        0 -> {year - 1, 12}
        13 -> {year + 1, 1}
        m -> {year, m}
      end

    Date.new!(new_year, new_month, 1)
  end

  defp format_month_year(date) do
    month_name =
      case date.month do
        1 -> "January"
        2 -> "February"
        3 -> "March"
        4 -> "April"
        5 -> "May"
        6 -> "June"
        7 -> "July"
        8 -> "August"
        9 -> "September"
        10 -> "October"
        11 -> "November"
        12 -> "December"
      end

    "#{month_name} #{date.year}"
  end
end
