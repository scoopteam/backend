defmodule Scoop.Repo do
  use Ecto.Repo,
    otp_app: :scoop,
    adapter: Ecto.Adapters.Postgres
end
