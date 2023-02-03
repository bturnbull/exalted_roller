defmodule ExaltedRollerWeb.Presence do
  use Phoenix.Presence, otp_app: :exalted_roller, pubsub_server: ExaltedRoller.PubSub
end
