defmodule PhoenixAuthExtendedTest.OAuth do
  @moduledoc """
  Multi-Provider OAuth Handler for Accounts authentication.
  """

  @spec request(String.t()) :: {:ok, map()} | {:error, term()}
  def request(provider) do
    config = config!(provider)
    config[:strategy].authorize_url(config)
  end

  @spec callback(String.t(), map(), map()) :: {:ok, map()} | {:error, term()}
  def callback(provider, params, session_params) do
    config = config!(provider)

    config
    |> Keyword.put(:session_params, session_params)
    |> config[:strategy].callback(params)
  end

  defp config!(provider) do
    provider = String.to_existing_atom(provider)

    config =
      Application.get_env(:phoenix_auth_extended, :oauth_providers)[provider] ||
        raise "No provider configuration found for #{provider}"

    Keyword.put(config, :redirect_uri, url(provider))
  end

  defp url(provider) do
    PhoenixAuthExtendedTestWeb.Endpoint.url() <> "/oauth/#{provider}/callback"
  end
end
