defmodule PhoenixAuthExtendedWeb.SessionController do
  use PhoenixAuthExtendedWeb, :controller

  alias PhoenixAuthExtended.Identity.User
  alias PhoenixAuthExtended.Identity
  alias PhoenixAuthExtendedWeb.Auth

  def create(conn, %{"_action" => "registered"} = params) do
    create(conn, params, "Account created successfully!")
  end

  def create(conn, %{"_action" => "password_updated"} = params) do
    conn
    |> put_session(:user_return_to, ~p"/users/settings")
    |> create(params, "Password updated successfully!")
  end

  def create(conn, params) do
    create(conn, params, "Welcome back!")
  end

  defp create(conn, %{"user" => user_params}, info) do
    %{"email" => email, "password" => password} = user_params

    if user = Identity.get_user_by_email_and_password(email, password) do
      conn
      |> put_flash(:info, info)
      |> Auth.log_in_user(user, user_params)
    else
      # In order to prevent user enumeration attacks, don't disclose whether the email is registered.
      conn
      |> put_flash(:error, "Invalid email or password")
      |> put_flash(:email, String.slice(email, 0, 160))
      |> redirect(to: ~p"/users/log_in")
    end
  end

  defp create(conn, %{"token" => token_params}, info) do
    %{"value" => value} = token_params
    decoded_value = Base.decode64!(value, padding: false)

    case Identity.get_user_by_token(decoded_value) do
      %User{} = user ->
        conn
        |> put_flash(:info, info)
        |> Auth.log_in_user(user)

      nil ->
        conn
        |> Auth.renew_session()
        |> put_flash(:error, "Please sign in.")
        |> redirect(to: ~p"/users/log_in")
    end
  end

  def delete(conn, _params) do
    conn
    |> put_flash(:info, "Logged out successfully.")
    |> Auth.log_out_user()
  end
end
