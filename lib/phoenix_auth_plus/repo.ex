defmodule PhoenixAuthPlus.Repo do
  use Ecto.Repo,
    otp_app: :phoenix_auth_plus,
    adapter: Ecto.Adapters.Postgres
end
