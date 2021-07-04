defmodule Wrench.Repo do
  use Ecto.Repo,
    otp_app: :wrench,
    adapter: Ecto.Adapters.Postgres
end
