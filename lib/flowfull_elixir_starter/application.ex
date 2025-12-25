defmodule FlowfullElixirStarter.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    redis_url = System.get_env("REDIS_URL")
    database_url = System.get_env("DATABASE_URL")

    children =
      [
        FlowfullElixirStarterWeb.Telemetry
        # Start Repo only if DATABASE_URL is provided
      ] ++
        if(is_binary(database_url), do: [FlowfullElixirStarter.Repo], else: []) ++
        [
          {DNSCluster,
           query: Application.get_env(:flowfull_elixir_starter, :dns_cluster_query) || :ignore},
          {Phoenix.PubSub, name: FlowfullElixirStarter.PubSub},
          {Cachex, name: :hybrid_cache}
          # Start Redix only if REDIS_URL is provided
        ] ++
        if(is_binary(redis_url), do: [{Redix, [name: :redis, url: redis_url]}], else: []) ++
        [
          # Start a worker by calling: FlowfullElixirStarter.Worker.start_link(arg)
          # {FlowfullElixirStarter.Worker, arg},
          # Start to serve requests, typically the last entry
          FlowfullElixirStarterWeb.Endpoint
        ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: FlowfullElixirStarter.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    FlowfullElixirStarterWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
