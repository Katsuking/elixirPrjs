defmodule DiaryWeb.TimerLiveTest do
  @moduledoc """
  Tests for TimerLive component page.
  Verifies successful mounting and presence of basic timer/stopwatch UI elements.
  """
  use DiaryWeb.ConnCase
  import Phoenix.LiveViewTest

  setup :register_and_log_in_user

  test "renders timer page and elements", %{conn: conn} do
    # Mount /timer page with authenticated user connection
    {:ok, _view, html} = live(conn, ~p"/timer")

    # Verify key timer and stopwatch structural elements exist in HTML
    assert html =~ "Timer"
    assert html =~ "Stopwatch"
    assert html =~ "03:00"
    assert html =~ "00:00.00"
  end
end
