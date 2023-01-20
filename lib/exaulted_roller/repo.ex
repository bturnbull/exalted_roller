defmodule ExaultedRoller.Repo do
  use Ecto.Repo,
    otp_app: :exaulted_roller,
    adapter: Ecto.Adapters.Postgres
end
