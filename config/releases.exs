import Config


secret_key_base = System.fetch_env!("SECRET_KEY_BASE")
application_port = System.fetch_env!("APP_PORT")

config :hexpm,
  secret: System.fetch_env!("HEXPM_SECRET"),
  private_key: System.fetch_env!("HEXPM_SIGNING_KEY"),
  s3_bucket: System.fetch_env!("HEXPM_S3_BUCKET"),

config :ex_aws,
  access_key_id: System.fetch_env!("HEXPM_AWS_ACCESS_KEY_ID"),
  secret_access_key: System.fetch_env!("HEXPM_AWS_ACCESS_KEY_SECRET")

config :kernel,
  inet_dist_listen_min: String.to_integer(System.fetch_env!("BEAM_PORT")),
  inet_dist_listen_max: String.to_integer(System.fetch_env!("BEAM_PORT"))


