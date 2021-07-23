use Mix.Config

config :wrench, Wrench.Hex.Api.Requester,
  api_key: File.read!("dev_hex_api_secret") |> String.trim()
