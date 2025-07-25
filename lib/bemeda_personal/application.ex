defmodule BemedaPersonal.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl Application
  def start(_type, _args) do
    children = [
      BemedaPersonalWeb.Telemetry,
      BemedaPersonal.Repo,
      {DNSCluster, query: Application.get_env(:bemeda_personal, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: BemedaPersonal.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: BemedaPersonal.Finch},
      {Registry, keys: :unique, name: BemedaPersonal.Registry},
      # Digital signatures infrastructure
      {Registry, keys: :unique, name: BemedaPersonal.DigitalSignatures.SessionRegistry},
      BemedaPersonal.DigitalSignatures.Providers.Mock,
      BemedaPersonal.DigitalSignatures.SessionSupervisor,
      {Oban, Application.fetch_env!(:bemeda_personal, Oban)},
      # Start a worker by calling: BemedaPersonal.Worker.start_link(arg)
      # {BemedaPersonal.Worker, arg},
      # Start to serve requests, typically the last entry
      BemedaPersonalWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: BemedaPersonal.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl Application
  def config_change(changed, _new, removed) do
    BemedaPersonalWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
