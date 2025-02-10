defmodule PhoenixAuthExtendedTest.Repo.Migrations.CreateUserTable do
  use Ecto.Migration

  def change do
    execute "CREATE EXTENSION IF NOT EXISTS citext", ""

    create table(:Users, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :email, :citext, null: false

      add :confirmed_at, :utc_datetime

      add :hashed_password, :string

      add :provider, :string
      add :provider_uid, :string

      timestamps(type: :utc_datetime)
    end

    create unique_index(:Users, [:email])

    create unique_index(:Users, [:provider, :provider_uid])
  end
end
