defmodule PhoenixAuthExtended.OAuth do
  @moduledoc """
  Multi-Provider OAuth Handler für die Auth-Generator Integration.
  """

  @spec request(atom()) :: {:ok, map()} | {:error, term()}
  def request(provider) do
    config = config!(provider)
    config[:strategy].authorize_url(config)
  end

  @spec callback(atom(), map(), map()) :: {:ok, map()} | {:error, term()}
  def callback(provider, params, session_params) do
    config = config!(provider)

    config
    |> Keyword.put(:session_params, session_params)
    |> config[:strategy].callback(params)
  end

  defp config!(provider) do
    config =
      Application.get_env(:phoenix_auth_extended, :oauth_providers)[provider] ||
        raise "No provider configuration for #{provider}"

    Keyword.put(config, :redirect_uri, url(provider))
  end

  defp url(provider) do
    PhoenixAuthExtendedWeb.Endpoint.url() <> "/oauth/#{provider}/callback"
  end
end
