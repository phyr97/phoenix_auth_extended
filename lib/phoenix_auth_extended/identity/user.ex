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
  Creates a changeset for basic email/password authentication.

  ## Options

    * `:validate_email` - Validates email uniqueness, defaults to true
    * `:validate_email_change` - Requires email to change, defaults to false
    * `:hash_password` - Hashes the password and stores it in hashed_password, defaults to true
    * `:validate_password` - Validates the password, defaults to true
  """
  def basic_changeset(user, attrs, opts \\ []) do
    regular_fields = __MODULE__.__schema__(:fields) -- [:hashed_password]
    virtual_fields = __MODULE__.__schema__(:virtual_fields)
    fields = regular_fields ++ virtual_fields

    user
    |> cast(attrs, fields)
    |> validate_email(:email, opts)
    |> maybe_validate_password(:password, opts)
    |> cast_assoc(:tokens)
  end

  @doc """
  Creates a changeset for passkey authentication.

  ## Options

    * `:validate_email` - Validates email uniqueness, defaults to true
    * `:validate_email_change` - Requires email to change, defaults to false
  """
  def passkey_changeset(user, attrs, opts \\ []) do
    fields = __MODULE__.__schema__(:fields)

    user
    |> cast(attrs, fields)
    |> validate_email(:email, opts)
    |> cast_assoc(:keys)
    |> cast_assoc(:tokens)
  end

  @doc """
  Creates a changeset for OAuth authentication.

  ## Options

    * `:validate_email` - Validates email uniqueness, defaults to true
    * `:validate_email_change` - Requires email to change, defaults to false
  """
  def oauth_changeset(user, attrs, opts \\ []) do
    fields = __MODULE__.__schema__(:fields)

    user
    |> cast(attrs, fields)
    |> validate_email(:email, opts)
    |> unique_constraint([:provider, :provider_uid])
  end

  @doc """
  Confirms the account by setting `confirmed_at` to the current time.
  """
  def confirm_changeset(user) do
    now = DateTime.utc_now() |> DateTime.truncate(:second)
    change(user, confirmed_at: now)
  end

  @doc """
  Validates the current password.

  Adds an error to the changeset if the provided password is invalid.
  """
  def validate_current_password(changeset, password) do
    changeset = cast(changeset, %{current_password: password}, [:current_password])
    user = changeset.data

    cond do
      is_nil(user.hashed_password) ->
        changeset

      valid_password?(user, password) ->
        changeset

      true ->
        add_error(changeset, :current_password, "is not valid")
    end
  end
end
