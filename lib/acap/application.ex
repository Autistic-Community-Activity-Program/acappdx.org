defmodule Acap.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    :logger.add_handler(:my_sentry_handler, Sentry.LoggerHandler, %{
      config: %{metadata: [:file, :line]}
    })

    children = [
      AcapWeb.Telemetry,
      Acap.Repo,
      {DNSCluster, query: Application.get_env(:acap, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Acap.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: Acap.Finch},
      # Start a worker by calling: Acap.Worker.start_link(arg)
      # {Acap.Worker, arg},
      # Start to serve requests, typically the last entry
      AcapWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Acap.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    AcapWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
