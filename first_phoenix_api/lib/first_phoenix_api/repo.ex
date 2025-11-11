defmodule FirstPhoenixApi.Repo do
  use Ecto.Repo,
    otp_app: :first_phoenix_api,
    adapter: Ecto.Adapters.Postgres
end
