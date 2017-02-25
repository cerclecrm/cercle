use Mix.Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :cercleApi, CercleApi.Endpoint,
  http: [port: 4001],
  server: false

# Print only warnings and errors during test
config :logger, level: :warn

# Configure your database
config :cercleApi, CercleApi.Repo,
  adapter: Ecto.Adapters.Postgres,
  username: "postgres",
  password: "postgres",
  database: "cercleapi_test",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox

# Guardian configuration
config :guardian, Guardian,
  secret_key: "W9cDv9fjPtsYv2gItOcFb5PzmRzqGkrOsJGmby0KpBOlHJIlhxMKFmIlcCG9PVFQ"
