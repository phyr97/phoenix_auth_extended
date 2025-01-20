defmodule PhoenixAuthExtendedWeb.OAuthController do
  use PhoenixAuthExtendedWeb, :controller

  alias PhoenixAuthExtended.{Identity, OAuth}
  alias PhoenixAuthExtendedWeb.UserAuth

  def request(conn, %{"provider" => provider}) do
    case OAuth.request(provider) do
      {:ok, %{url: url, session_params: session_params}} ->
        conn
        |> put_session(:oauth_session_params, session_params)
        |> redirect(external: url)

      {:error, _error} ->
        conn
        |> put_flash(:error, "Authentication failed")
        |> redirect(to: ~p"/users/log_in")
    end
  end

  def callback(conn, %{"provider" => provider} = params) do
    session_params = get_session(conn, :oauth_session_params)

    with {:ok, %{user: user_info}} <- OAuth.callback(provider, params, session_params),
         user_params = %{
           email: user_info["email"],
           provider: provider,
           provider_uid: user_info["sub"]
         },
         {:ok, user} <- Identity.get_or_create_user(user_params) do
      conn
      |> delete_session(:oauth_session_params)
      |> UserAuth.log_in_user(user, %{})
    else
      {:error, _reason} ->
        conn
        |> put_flash(:error, "Authentication failed")
        |> redirect(to: ~p"/users/log_in")
    end
  end
end
