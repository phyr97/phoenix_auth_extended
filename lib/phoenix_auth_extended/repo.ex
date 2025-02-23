defmodule PhoenixAuthExtended.Repo do
  use Ecto.Repo,
    otp_app: :phoenix_auth_extended,
    adapter: Ecto.Adapters.Postgres
end
