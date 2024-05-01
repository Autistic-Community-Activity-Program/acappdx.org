defmodule Acap.Repo do
  use Ecto.Repo,
    otp_app: :acap,
    adapter: Ecto.Adapters.Postgres
end
