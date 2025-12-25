defmodule FlowfullElixirStarterWeb.Router do
  use FlowfullElixirStarterWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {FlowfullElixirStarterWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
    plug FlowfullElixirStarter.Auth.OptionalMiddleware
  end

  pipeline :api_auth do
    plug :accepts, ["json"]
    plug FlowfullElixirStarter.Auth.Middleware
  end

  scope "/", FlowfullElixirStarterWeb do
    pipe_through :browser

    get "/", PageController, :home
  end

  scope "/api", FlowfullElixirStarterWeb do
    pipe_through :api

    # Public
    get "/health", PageController, :health
    get "/public", SampleController, :public
    get "/content", SampleController, :content
  end

  scope "/", FlowfullElixirStarterWeb do
    pipe_through :browser

    get "/ws", PageController, :ws
  end

  scope "/api/secure", FlowfullElixirStarterWeb do
    pipe_through :api_auth

    get "/me", PageController, :me
    get "/profile", SampleController, :profile
    get "/protected", SampleController, :protected
    get "/admin/dashboard", SampleController, :admin_dashboard
    get "/admin/users", SampleController, :admin_users
    get "/admin/users/:id", SampleController, :admin_user
    get "/users", SampleController, :admin_users
    get "/users/:id", SampleController, :admin_user
  end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:flowfull_elixir_starter, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: FlowfullElixirStarterWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
