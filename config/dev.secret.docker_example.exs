use Mix.Config

# In this file, we keep production configuration that
# you likely want to automate and keep it away from
# your version control system.
# Configure your database
config :cercleApi, CercleApi.Repo,
  adapter: Ecto.Adapters.Postgres,
  username: System.get_env("DB_USER"),
  password: System.get_env("DB_PASS"),
  database: System.get_env("DB_NAME"),
  hostname: System.get_env("DB_HOST"),
  pool_size: 10

config :arc,
  bucket: System.get_env("AWS_BUCKET"),
  virtual_host: true

config :ex_aws,
  access_key_id: System.get_env("AWS_KEY"),
  secret_access_key: System.get_env("AWS_SECRET"),
  region: System.get_env("AWS_REGION")

config :cercleApi, basic_auth: [
    username: "admin",
    password: "admin",
    realm: "Admin Area"
  ]

config :mailman,
  relay: System.get_env("SMTP_HOST"),            
  port: System.get_env("SMTP_PORT"),
  username: System.get_env("SMTP_USER"),
  password: System.get_env("SMTP_PASS"),
  tls: :always
