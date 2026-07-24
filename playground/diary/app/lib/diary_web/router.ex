defmodule DiaryWeb.Router do
  use DiaryWeb, :router

  import DiaryWeb.UserAuth

  # --------------------------
  # 1️⃣ 許可ロケールのホワイトリスト
  # --------------------------
  @allowed_locales ~w(en ja)   # ← ここで許可する言語コードを列挙 (strings)
  # en : English
  # ja : Japanese

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :fetch_query_params
    plug :put_root_layout, html: {DiaryWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_scope_for_user
    plug :set_locale
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  # -------------------------------------------------
  # ロケール決定プラグ（クエリがあれば常に上書き）
  # -------------------------------------------------
  defp set_locale(conn, _opts) do
    # クエリパラメータ取得
    IO.inspect(conn.params, label: "[DEBUG] request params")
    query_locale = conn.params["locale"]
    # セッションかデフォルトで決定
    locale =
      if query_locale && query_locale in @allowed_locales do
        query_locale
      else
        get_session(conn, :locale) || "en"
      end
    Gettext.put_locale(DiaryWeb.Gettext, locale)
    # クエリがあればセッションに保存（次回リクエストで保持）
    conn =
      if query_locale && query_locale in @allowed_locales do
        Plug.Conn.put_session(conn, :locale, query_locale)
      else
        conn
      end
    conn
  end

  scope "/", DiaryWeb do
    pipe_through :browser

    # Root live routes have been moved to the authenticated live_session below
  end

  # Other scopes may use custom stacks.
  # scope "/api", DiaryWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:diary, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: DiaryWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  ## Authentication routes

  scope "/", DiaryWeb do
    pipe_through [:browser, :require_authenticated_user]

    live_session :require_authenticated_user,
      on_mount: [{DiaryWeb.UserAuth, :require_authenticated}] do
      # Core application routes requiring login
      live "/", DiaryLive
      live "/stats", StatsLive
      live "/workout/:date", WorkoutLive

      live "/users/settings", UserLive.Settings, :edit
      live "/users/settings/confirm-email/:token", UserLive.Settings, :confirm_email
    end

    post "/users/update-password", UserSessionController, :update_password
  end

  scope "/", DiaryWeb do
    pipe_through [:browser]

    live_session :current_user,
      on_mount: [{DiaryWeb.UserAuth, :mount_current_scope}] do
      live "/users/register", UserLive.Registration, :new
      live "/users/log-in", UserLive.Login, :new
      live "/users/log-in/:token", UserLive.Confirmation, :new
    end

    post "/users/log-in", UserSessionController, :create
    delete "/users/log-out", UserSessionController, :delete
  end
end
