defmodule PhoenixAuthExtended.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      PhoenixAuthExtendedWeb.Telemetry,
      PhoenixAuthExtended.Repo,
      {DNSCluster, query: Application.get_env(:phoenix_auth_extended, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: PhoenixAuthExtended.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: PhoenixAuthExtended.Finch},
      # Start a worker by calling: PhoenixAuthExtended.Worker.start_link(arg)
      # {PhoenixAuthExtended.Worker, arg},
      # Start to serve requests, typically the last entry
      PhoenixAuthExtendedWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: PhoenixAuthExtended.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    PhoenixAuthExtendedWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
