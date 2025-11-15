defmodule FirstStepWeb.Router do
  use FirstStepWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {FirstStepWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", FirstStepWeb do
    pipe_through :browser

    get "/", HomeController, :index
    get "/hello", HomeController, :hello
  end

  # Other scopes may use custom stacks.
  # scope "/api", FirstStepWeb do
  #   pipe_through :api
  # end
end
