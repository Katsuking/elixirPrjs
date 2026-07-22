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

  test "displays aggregated training volume on the homepage", %{conn: conn} do
    # Insert 3 workout logs for today (representing 3 sets of 100 kg * 10 reps = 3000 kg volume)
    # Bench Press targets Chest ("胸") at 75% -> 2250.0 kg chest volume
    today = Date.utc_today()
    {:ok, _log1} = Notebook.save_workout_log(today, "ベンチプレス", 100.0, 10)
    {:ok, _log2} = Notebook.save_workout_log(today, "ベンチプレス", 100.0, 10)
    {:ok, _log3} = Notebook.save_workout_log(today, "ベンチプレス", 100.0, 10)

    # Fetch homepage
    {:ok, view, html} = live(conn, ~p"/")

    # Should render "Training Volume"
    assert html =~ "Training Volume"

    # Chest targets should now show volume
    # Bench Press: 3 sets * 100 kg * 10 reps * 75% = 2250.0 kg
    assert html =~ "Chest"
    assert html =~ "2250.0 kg"

    # Toggle detail view
    detail_html = view |> element("button", "Show Details") |> render_click()
    assert detail_html =~ "Show General"
    # Detailed breakdown part: "中部" (Middle) for Chest
    assert detail_html =~ "Middle"

    # Switch stats period tabs
    monthly_html = view |> element("button", "Monthly") |> render_click()
    assert monthly_html =~ "Monthly"

    yearly_html = view |> element("button", "Yearly") |> render_click()
    assert yearly_html =~ "Yearly"
  end
end
