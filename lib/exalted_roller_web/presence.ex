defmodule ExaultedRollerWeb.Presence do
  use Phoenix.Presence, otp_app: :exaulted_roller, pubsub_server: ExaultedRoller.PubSub
end
