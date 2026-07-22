defmodule DiaryWeb.WorkoutLiveTest do
  use DiaryWeb.ConnCase
  import Phoenix.LiveViewTest

  alias Diary.Notebook

  test "renders workout logger, filters by muscle group, and logs a workout", %{conn: conn} do
    date_str = "2026-07-22"
    {:ok, view, html} = live(conn, ~p"/workout/#{date_str}")

    # Verify the page header
    assert html =~ "Workout Logger"

    # Select "胸" (Chest) muscle group
    view |> element("button[phx-click='select_group'][phx-value-group='胸']") |> render_click()

    # Verify that chest exercises like "ベンチプレス" are rendered
    assert render(view) =~ "ベンチプレス"

    # Click on "ベンチプレス" to select it
    view |> element("button[phx-value-exercise='ベンチプレス']") |> render_click()

    # Fill in the form: 100.0 kg, 10 reps (sets input is removed)
    form_params = %{
      "log" => %{
        "weight" => "100.0",
        "reps" => "10"
      }
    }

    # Submit the form to save the log entry
    result_html = view |> form("#workout-log-form") |> render_submit(form_params)

    # Check for success flash message
    assert result_html =~ "Workout log saved!"

    # Verify that the exercise is listed under Today's Workouts
    assert result_html =~ "ベンチプレス"
    assert result_html =~ "100.0 kg × 10 reps"
  end

  test "displays aggregated training volume on the homepage and stats page", %{conn: conn} do
    # Insert 3 workout logs for today (representing 3 sets of 100 kg * 10 reps = 3000 kg volume)
    # Bench Press targets Chest ("胸") at 75% -> 2250.0 kg chest volume
    today = Date.utc_today()
    {:ok, _log1} = Notebook.save_workout_log(today, "ベンチプレス", 100.0, 10)
    {:ok, _log2} = Notebook.save_workout_log(today, "ベンチプレス", 100.0, 10)
    {:ok, _log3} = Notebook.save_workout_log(today, "ベンチプレス", 100.0, 10)

    # Fetch homepage (diary page) and verify today's volume is shown in English
    {:ok, _diary_view, diary_html} = live(conn, ~p"/")
    assert diary_html =~ "Today&#39;s Volume"
    assert diary_html =~ "3000.0 kg"

    # Verify today's volume on homepage in Japanese
    {:ok, _diary_view_ja, diary_html_ja} = live(conn, ~p"/?locale=ja")
    assert diary_html_ja =~ "本日の総重量"
    assert diary_html_ja =~ "3000.0 kg"

    # Fetch stats page
    {:ok, view, html} = live(conn, ~p"/stats")

    # Should render "Training Volume"
    assert html =~ "Training Volume"

    # Chest targets should now show volume
    # Bench Press: 3 sets * 100 kg * 10 reps * 75% = 2250.0 kg
    assert html =~ "Chest"
    assert html =~ "2250.0 kg"

    # Toggle detail view
    detail_html = view |> element("button[phx-click=\"toggle_stats_detail\"]") |> render_click()
    assert detail_html =~ "Show General"
    # Detailed breakdown part: "中部" (Middle) for Chest
    assert detail_html =~ "Middle"

    # Switch stats period tabs
    daily_html = view |> element("button", "Daily") |> render_click()
    assert daily_html =~ "Daily"

    monthly_html = view |> element("button", "Monthly") |> render_click()
    assert monthly_html =~ "Monthly"

    yearly_html = view |> element("button", "Yearly") |> render_click()
    assert yearly_html =~ "Yearly"
  end

  test "displays localized validation error when logging invalid workout values", %{conn: conn} do
    date_str = "2026-07-22"
    
    # Test English locale errors
    {:ok, view_en, _html} = live(conn, ~p"/workout/#{date_str}?locale=en")
    view_en |> element("button[phx-click='select_group'][phx-value-group='胸']") |> render_click()
    view_en |> element("button[phx-value-exercise='ベンチプレス']") |> render_click()

    form_params_invalid = %{"log" => %{"weight" => "-10.0", "reps" => "-5"}}
    result_en = view_en |> form("#workout-log-form") |> render_submit(form_params_invalid)
    assert result_en =~ "must be greater than or equal to 0"
    assert result_en =~ "must be greater than 0"

    # Test Japanese locale errors
    {:ok, view_ja, _html} = live(conn, ~p"/workout/#{date_str}?locale=ja")
    view_ja |> element("button[phx-click='select_group'][phx-value-group='胸']") |> render_click()
    view_ja |> element("button[phx-value-exercise='ベンチプレス']") |> render_click()

    result_ja = view_ja |> form("#workout-log-form") |> render_submit(form_params_invalid)
    assert result_ja =~ "0以上の値にしてください"
    assert result_ja =~ "0より大きい値にしてください"
  end
end
