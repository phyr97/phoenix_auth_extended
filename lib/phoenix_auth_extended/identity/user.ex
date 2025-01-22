defmodule PhoenixAuthExtended.Identity.User do
  use Ecto.Schema
  import Ecto.Changeset
  import PhoenixAuthExtended.Validation

  alias PhoenixAuthExtended.Identity.{UserKey, UserToken}

  @primary_key {:id, Ecto.ULID, autogenerate: true}
  @foreign_key_type Ecto.ULID
  schema "users" do
    field :email, :string
    field :password, :string, virtual: true, redact: true
    field :hashed_password, :string, redact: true
    field :current_password, :string, virtual: true, redact: true
    field :confirmed_at, :utc_datetime
    field :provider, :string
    field :provider_uid, :string

    has_many :keys, UserKey, preload_order: [desc: :last_used_at]
    has_many :tokens, UserToken, preload_order: [desc: :inserted_at]

    timestamps(type: :utc_datetime)
  end

  @doc """
  Creates a changeset for passkey authentication.
  """
  def passkey_changeset(user, attrs, opts \\ [unique: true]) do
    fields = __MODULE__.__schema__(:fields)

    user
    |> cast(attrs, fields)
    |> validate_email(:email, opts)
    |> cast_assoc(:keys)
    |> cast_assoc(:tokens)
  end

  @doc """
  Creates a changeset for OAuth authentication.
  """
  def oauth_changeset(user, attrs, opts \\ [unique: true]) do
    fields = __MODULE__.__schema__(:fields)

    user
    |> cast(attrs, fields)
    |> validate_email(:email, opts)
    |> unique_constraint([:provider, :provider_uid])
  end

  @doc """
  Creates a changeset for basic email/password authentication.
  """
  def basic_changeset(user, attrs, opts \\ [unique: true, hash_password: true]) do
    regular_fields = __MODULE__.__schema__(:fields) -- [:hashed_password]
    virtual_fields = __MODULE__.__schema__(:virtual_fields)
    fields = regular_fields ++ virtual_fields

    user
    |> cast(attrs, fields)
    |> validate_email(:email, opts)
    |> validate_password(:password, opts)
    |> cast_assoc(:tokens)
  end

  @doc """
  Confirms the account by setting `confirmed_at`.
  """
  def confirm_changeset(user) do
    now = DateTime.utc_now() |> DateTime.truncate(:second)
    change(user, confirmed_at: now)
  end
end
