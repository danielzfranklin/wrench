# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

config :wrench,
  ecto_repos: [Wrench.Repo],
  operator_contact: "daniel@danielzfranklin.org"

# Configures the endpoint
config :wrench, WrenchWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "y1V7kv6O22X6RK8INdpXGOf/yYQhBdjyu+pqO0MOfkG2akDVIL1pCiZhUy5ESSYI",
  render_errors: [view: WrenchWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: Wrench.PubSub,
  live_view: [signing_salt: "+KJFk9Y+"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

config :elixir, :time_zone_database, Tzdata.TimeZoneDatabase

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
