defmodule ExaultedRollerWeb.Router do
  use ExaultedRollerWeb, :router

  import ExaultedRollerWeb.UserAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {ExaultedRollerWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_player
    plug :fetch_current_table
  end

  #### pipeline :api do
  ####   plug :accepts, ["json"]
  #### end

  #### scope "/", ExaultedRollerWeb do
  ####   pipe_through :browser
  ####
  ####   get "/", PageController, :home
  #### end

  # Other scopes may use custom stacks.
  # scope "/api", ExaultedRollerWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard in development
  if Application.compile_env(:exaulted_roller, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: ExaultedRollerWeb.Telemetry
    end
  end

  scope "/", ExaultedRollerWeb do
    pipe_through [:browser, :require_joined_player]

    live_session :require_joined_player,
      on_mount: [{ExaultedRollerWeb.UserAuth, :ensure_joined}] do
      live "/", RollerLive, :edit
    end
  end

  scope "/", ExaultedRollerWeb do
    pipe_through [:browser, :redirect_if_player_is_joined]

    live_session :redirect_if_player_is_joined,
      on_mount: [{ExaultedRollerWeb.UserAuth, :redirect_if_player_is_joined}] do
      live "/join", PlayerJoinLive, :new
    end

    post "/join", PlayerSessionController, :create
  end

  scope "/", ExaultedRollerWeb do
    pipe_through [:browser]

    delete "/leave", PlayerSessionController, :delete
  end
end
