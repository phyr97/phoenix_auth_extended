defmodule PhoenixAuthExtendedTest.Repo.Migrations.CreateUserTokensTable do
  use Ecto.Migration

  def change do
    create table(:User_tokens, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :value, :binary, null: false
      add :type, :string, null: false

      add :sent_to, :string

      add :User_id, references(:Users, on_delete: :delete_all, type: :binary_id), null: false

      timestamps(type: :utc_datetime, updated_at: false)
    end

    create index(:User_tokens, [:User_id])
    create unique_index(:User_tokens, [:type, :value])
  end
end
