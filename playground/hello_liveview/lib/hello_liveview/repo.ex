defmodule HelloLiveview.Repo do
  use Ecto.Repo,
    otp_app: :hello_liveview,
    adapter: Ecto.Adapters.Postgres
end
