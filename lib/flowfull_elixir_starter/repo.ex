defmodule FlowfullElixirStarter.Repo do
  use Ecto.Repo,
    otp_app: :flowfull_elixir_starter,
    adapter: Ecto.Adapters.Postgres
end
