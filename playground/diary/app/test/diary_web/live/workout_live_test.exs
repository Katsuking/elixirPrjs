defmodule DiaryWeb.WorkoutLiveTest do
  use DiaryWeb.ConnCase
  import Phoenix.LiveViewTest

  test "renders workout logs page and permits weight logging", %{conn: conn} do
    # Go to a specific date's workout page
    date_str = "2026-07-22"
    {:ok, view, html} = live(conn, ~p"/workout/#{date_str}")

    # Should render header
    assert html =~ "Training Logs"

    # Should render exercise inputs
    assert html =~ "ベンチプレス"

    # Input weight for Bench Press and save it
    # We trigger form change which saves weight via phx-change
    weights_params = %{
      "weights" => %{
        "ベンチプレス" => "100"
      }
    }

    # Triggering the form change should update state
    form_html = view |> form("form[phx-change='save_weight']", weights_params) |> render_change()

    # Weights updated message
    assert form_html =~ "Weights updated!"

    # The stats volume should now reflect the Bench Press weight distributed (e.g. 75 kg for Chest/胸)
    assert form_html =~ "胸"
    # Bench press weight 100 * 75% = 75.0 kg
    assert form_html =~ "75.0 kg"

    # Toggle detailed view
    detail_html = view |> element("button", "Show Details") |> render_click()
    assert detail_html =~ "Show General"
    assert detail_html =~ "中部" # Detailed breakdown for Chest
  end

  test "tab switching between weekly, monthly, and yearly stats", %{conn: conn} do
    date_str = "2026-07-22"
    {:ok, view, _html} = live(conn, ~p"/workout/#{date_str}")

    # Switch to monthly tab
    monthly_html = view |> element("button", "Monthly") |> render_click()
    # Check that Monthly is active/visible
    assert monthly_html =~ "Monthly"

    # Switch to yearly tab
    yearly_html = view |> element("button", "Yearly") |> render_click()
    assert yearly_html =~ "Yearly"
  end
end
