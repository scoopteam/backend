# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

config :scoop,
  ecto_repos: [Scoop.Repo]

# Configures the endpoint
config :scoop, ScoopWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "spuZD/OLDPxyxqVhviifHJ1YhOo3/4yGSzY+VJtMYKROnaddimDBVykV3sOIlE+T",
  render_errors: [view: ScoopWeb.ErrorView, accepts: ~w(json)],
  live_view: [signing_salt: System.get_env("SECRET_SALT", :crypto.strong_rand_bytes(32) |> Base.encode16)]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
