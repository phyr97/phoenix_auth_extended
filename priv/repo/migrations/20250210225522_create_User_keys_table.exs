defmodule PhoenixAuthExtendedTest.Repo.Migrations.Create_UserKeysTable do
  use Ecto.Migration

  def change do
    create table(:User_keys, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :User_id, references(:Users, on_delete: :delete_all, type: :binary_id), null: false
      add :label, :string, null: false
      add :key_id, :binary, null: false
      add :public_key, :binary, null: false
      add :last_used_at, :utc_datetime, null: false, default: fragment("now()")

      timestamps()
    end

    create index(:User_keys, [:User_id])
    create unique_index(:User_keys, [:key_id])
    create unique_index(:User_keys, [:User_id, :label])
  end
end
