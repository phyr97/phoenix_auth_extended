defmodule PhoenixAuthExtended.Validation do
  import Ecto.Changeset

  def validate_password(changeset, field, opts) do
    changeset
    |> validate_required(field)
    |> validate_length(field, min: 8, max: 72)
    # Examples of additional password validation:
    # |> validate_format(:password, ~r/[a-z]/, message: "at least one lower case character")
    # |> validate_format(:password, ~r/[A-Z]/, message: "at least one upper case character")
    # |> validate_format(:password, ~r/[!?@#$%^&*_0-9]/, message: "at least one digit or punctuation character")
    |> maybe_hash_password(field, opts)
  end

  defp maybe_hash_password(changeset, field, opts) do
    hash_password? = Keyword.get(opts, :hash_password, true)
    password = get_change(changeset, field)

    if hash_password? && password && changeset.valid? do
      changeset
      # If using Bcrypt, then further validate it is at most 72 bytes long
      |> validate_length(field, max: 72, count: :bytes)
      # Hashing could be done with `Ecto.Changeset.prepare_changes/2`, but that
      # would keep the database transaction open longer and hurt performance.
      |> put_change(:hashed_password, Bcrypt.hash_pwd_salt(password))
      |> delete_change(field)
    else
      changeset
    end
  end

  @doc """
  Validates the current password otherwise adds an error to the changeset.
  """
  def validate_current_password(changeset, password) do
    changeset = cast(changeset, %{current_password: password}, [:current_password])

    if valid_password?(changeset.data, password) do
      changeset
    else
      add_error(changeset, :current_password, "is not valid")
    end
  end

  @doc """
  Verifies the password.

  If there is no user or the user doesn't have a password, we call
  `Bcrypt.no_user_verify/0` to avoid timing attacks.
  """
  def valid_password?(%{hashed_password: hashed_password}, password)
      when is_binary(hashed_password) and byte_size(password) > 0 do
    Bcrypt.verify_pass(password, hashed_password)
  end

  def valid_password?(_, _) do
    Bcrypt.no_user_verify()
    false
  end

  def validate_email(changeset, field, opts) do
    changeset
    |> validate_required(field)
    |> validate_format(field, ~r/^[^\s]+@[^\s]+$/, message: "must have the @ sign and no spaces")
    |> validate_length(field, max: 160)
    |> maybe_validate_unique_email(field, opts)
  end

  defp maybe_validate_unique_email(changeset, field, opts) do
    if Keyword.get(opts, :unique, true) do
      changeset
      |> unsafe_validate_unique(field, PhoenixAuthExtended.Repo)
      |> unique_constraint(field)
    else
      changeset
    end
  end
end
