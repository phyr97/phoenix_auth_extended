defmodule PhoenixAuthExtendedWeb.Router do
  use PhoenixAuthExtendedWeb, :router

  import PhoenixAuthExtendedWeb.Auth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {PhoenixAuthExtendedWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_user
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", PhoenixAuthExtendedWeb do
    pipe_through :browser

    get "/", PageController, :home
  end

  # Other scopes may use custom stacks.
  # scope "/api", PhoenixAuthExtendedWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:phoenix_auth_extended, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: PhoenixAuthExtendedWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  ## Authentication routes

  scope "/", PhoenixAuthExtendedWeb do
    pipe_through [:browser, :redirect_if_user_is_authenticated]

    live_session :redirect_if_user_is_authenticated,
      on_mount: [{PhoenixAuthExtendedWeb.Auth, :redirect_if_user_is_authenticated}] do
      live "/users/register", RegistrationLive, :new
      live "/users/register_with_passkey", PasskeyRegistrationLive, :new
      live "/users/log_in", LoginLive, :new
      live "/users/reset_password", ForgotPasswordLive, :new
      live "/users/reset_password/:token", ResetPasswordLive, :edit
    end

    get "/oauth/:provider", OAuthController, :request
    get "/oauth/:provider/callback", OAuthController, :callback
    post "/users/log_in", SessionController, :create
  end

  scope "/", PhoenixAuthExtendedWeb do
    pipe_through [:browser, :require_authenticated_user]

    live_session :require_authenticated_user,
      on_mount: [{PhoenixAuthExtendedWeb.Auth, :ensure_authenticated}] do
      live "/users/settings", SettingsLive, :edit
      live "/users/settings/confirm_email/:token", SettingsLive, :confirm_email
    end
  end

  scope "/", PhoenixAuthExtendedWeb do
    pipe_through [:browser]

    delete "/users/log_out", SessionController, :delete

    live_session :current_user,
      on_mount: [{PhoenixAuthExtendedWeb.Auth, :mount_current_user}] do
      live "/users/confirm/:token", ConfirmationLive, :edit
      live "/users/confirm", ConfirmationInstructionsLive, :new
    end
  end
end
