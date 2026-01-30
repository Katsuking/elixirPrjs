defmodule HelloWeb.Router do
  use HelloWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", HelloWeb do
    pipe_through :api

    get "/ping", Ping.PingController, :index # routingの追加
    get "/ping/:id", Ping.PingController, :show # url param を取得

    get "/sample", Sample.SampleController, :index

    resources "/notices", NoticeController, except: [:new, :edit] # [:new, :edit] はAPIには不要なので除外
  end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:hello, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through [:fetch_session, :protect_from_forgery]

      live_dashboard "/dashboard", metrics: HelloWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
