defmodule PhoenixAuthExtendedTest.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      PhoenixAuthExtendedTestWeb.Telemetry,
      PhoenixAuthExtendedTest.Repo,
      {DNSCluster, query: Application.get_env(:phoenix_auth_extended_test, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: PhoenixAuthExtendedTest.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: PhoenixAuthExtendedTest.Finch},
      # Start a worker by calling: PhoenixAuthExtendedTest.Worker.start_link(arg)
      # {PhoenixAuthExtendedTest.Worker, arg},
      # Start to serve requests, typically the last entry
      PhoenixAuthExtendedTestWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: PhoenixAuthExtendedTest.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    PhoenixAuthExtendedTestWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
