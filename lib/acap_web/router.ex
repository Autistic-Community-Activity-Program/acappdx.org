defmodule AcapWeb.Router do
  use AcapWeb, :router

  import AcapWeb.UserAuth
  import Phoenix.LiveDashboard.Router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {AcapWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_user
  end

  pipeline :admin_layout do
    plug :put_root_layout, html: {AcapWeb.Layouts, :admin}
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", AcapWeb do
    pipe_through :browser
    get "/", PageController, :home
    get "/about", PageController, :about
    get "/about/history", PageController, :history
    get "/about/staff", PageController, :staff
    get "/programs", PageController, :programs
    get "/programs/summer-camp", PageController, :summer
    get "/programs/projects", PageController, :projects
    get "/employment", PageController, :employment
    get "/employment/handbook", PageController, :handbook
    get "/support/donating", PageController, :donating
    get "/support/fundraising", PageController, :fundraising
    get "/support/volunteering", PageController, :volunteering
    get "/contact", PageController, :contact
    get "/terms", PageController, :terms
    get "/privacy", PageController, :privacy

  end

  # Other scopes may use custom stacks.
  # scope "/api", AcapWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:acap, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    scope "/dev" do
      pipe_through :browser
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  ## Authentication routes

  scope "/", AcapWeb do
    pipe_through [:browser, :redirect_if_user_is_authenticated]

    get "/users/register", UserRegistrationController, :new
    post "/users/register", UserRegistrationController, :create
    get "/users/log_in", UserSessionController, :new
    post "/users/log_in", UserSessionController, :create
    get "/users/log_in/2fa", UserSessionController, :verify
    post "/users/log_in/2fa", UserSessionController, :verify

    get "/users/reset_password", UserResetPasswordController, :new
    post "/users/reset_password", UserResetPasswordController, :create
    get "/users/reset_password/:token", UserResetPasswordController, :edit
    put "/users/reset_password/:token", UserResetPasswordController, :update
  end

  scope "/admin", AcapWeb do
    pipe_through [:browser, :require_authenticated_admin, :admin_layout]

    live_dashboard "/dashboard", metrics: AcapWeb.Telemetry
    post "/timesheets/export", TimesheetController, :export
    resources "/accounts", AccountsController
    resources "/timesheets", TimesheetController
  end

  scope "/", AcapWeb do
    pipe_through [:browser, :require_authenticated_user]

    get "/users/settings", UserSettingsController, :edit
    put "/users/settings", UserSettingsController, :update
    get "/users/settings/confirm_email/:token", UserSettingsController, :confirm_email
    resources "/timesheets", TimesheetController

  end

  scope "/", AcapWeb do
    pipe_through [:browser]

    delete "/users/log_out", UserSessionController, :delete
    get "/users/confirm", UserConfirmationController, :new
    post "/users/confirm", UserConfirmationController, :create
    get "/users/confirm/:token", UserConfirmationController, :edit
    post "/users/confirm/:token", UserConfirmationController, :update
  end
end
