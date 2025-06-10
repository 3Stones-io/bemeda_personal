defmodule BemedaPersonalWeb.Router do
  use BemedaPersonalWeb, :router

  import BemedaPersonalWeb.UserAuth

  alias BemedaPersonalWeb.Locale

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {BemedaPersonalWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_user
    plug Locale
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", BemedaPersonalWeb do
    pipe_through [:browser, :assign_current_user]

    get "/", PageController, :home

    live_session :public_routes,
      on_mount: [
        {BemedaPersonalWeb.UserAuth, :mount_current_user},
        {BemedaPersonalWeb.LiveHelpers, :assign_locale}
      ] do
      live "/jobs", JobLive.Index, :index
      live "/jobs/:id", JobLive.Show, :show
      live "/companies/:id", CompanyPublicLive.Show, :show
      live "/companies/:id/jobs", CompanyPublicLive.Jobs, :jobs
    end
  end

  # Other scopes may use custom stacks.
  # scope "/api", BemedaPersonalWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:bemeda_personal, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: BemedaPersonalWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  resources "/health", BemedaPersonalWeb.HealthController, only: [:index]

  scope "/", BemedaPersonalWeb do
    pipe_through [:browser, :redirect_if_user_is_authenticated]

    live_session :redirect_if_user_is_authenticated,
      on_mount: [
        {BemedaPersonalWeb.UserAuth, :redirect_if_user_is_authenticated},
        {BemedaPersonalWeb.LiveHelpers, :assign_locale}
      ] do
      live "/users/register", UserRegistrationLive, :new
      live "/users/register/:type", UserRegistrationLive, :register
      live "/users/log_in", UserLoginLive, :new
      live "/users/reset_password", UserForgotPasswordLive, :new
      live "/users/reset_password/:token", UserResetPasswordLive, :edit
    end

    post "/users/log_in", UserSessionController, :create
  end

  scope "/", BemedaPersonalWeb do
    pipe_through [:browser, :require_authenticated_user]

    live_session :require_authenticated_user,
      on_mount: [
        {BemedaPersonalWeb.UserAuth, :ensure_authenticated},
        {BemedaPersonalWeb.LiveHelpers, :assign_locale}
      ] do
      live "/users/settings", UserSettingsLive, :edit
      live "/users/settings/confirm_email/:token", UserSettingsLive, :confirm_email

      # Resume routes
      live "/resume", Resume.ShowLive, :show
      live "/resume/edit", Resume.ShowLive, :edit_resume
      live "/resume/education/new", Resume.ShowLive, :new_education
      live "/resume/education/:id/edit", Resume.ShowLive, :edit_education
      live "/resume/work-experience/new", Resume.ShowLive, :new_work_experience
      live "/resume/work-experience/:id/edit", Resume.ShowLive, :edit_work_experience

      # Job application routes
      live "/job_applications", JobApplicationLive.Index, :index
      live "/jobs/:job_id/job_applications/new", JobApplicationLive.Index, :new
      live "/jobs/:job_id/job_applications/:id/edit", JobApplicationLive.Index, :edit
      live "/jobs/:job_id/job_applications/:id", JobApplicationLive.Show, :show
      live "/jobs/:job_id/job_applications/:id/history", JobApplicationLive.History, :show

      live "/notifications", NotificationLive.Index, :index
      live "/notifications/:id", NotificationLive.Show, :show
    end
  end

  scope "/company", BemedaPersonalWeb do
    pipe_through [
      :browser,
      :require_authenticated_user,
      :require_employer_user_type,
      :require_user_company
    ]

    live_session :user_company,
      on_mount: [
        {BemedaPersonalWeb.UserAuth, :ensure_authenticated},
        {BemedaPersonalWeb.UserAuth, :require_user_company},
        {BemedaPersonalWeb.LiveHelpers, :assign_locale}
      ] do
      live "/", CompanyLive.Index, :index
      live "/edit", CompanyLive.Index, :edit
      live "/jobs", CompanyJobLive.Index, :index
      live "/jobs/new", CompanyJobLive.Index, :new
      live "/jobs/:id", CompanyJobLive.Show, :show
      live "/jobs/:id/edit", CompanyJobLive.Index, :edit
      live "/applicants", CompanyApplicantLive.Index, :index
      live "/applicants/:job_id", CompanyApplicantLive.Index, :index
      live "/applicant/:id", CompanyApplicantLive.Show, :show
    end
  end

  scope "/company", BemedaPersonalWeb do
    pipe_through [
      :browser,
      :require_authenticated_user,
      :require_employer_user_type,
      :require_no_existing_company
    ]

    live_session :new_company,
      on_mount: [
        {BemedaPersonalWeb.UserAuth, :ensure_authenticated},
        {BemedaPersonalWeb.UserAuth, :require_no_existing_company},
        {BemedaPersonalWeb.LiveHelpers, :assign_locale}
      ] do
      live "/new", CompanyLive.Index, :new
    end
  end

  scope "/", BemedaPersonalWeb do
    pipe_through [:browser]

    get "/locale/:locale", LocaleController, :set
    delete "/users/log_out", UserSessionController, :delete

    live_session :current_user,
      on_mount: [
        {BemedaPersonalWeb.UserAuth, :mount_current_user},
        {BemedaPersonalWeb.LiveHelpers, :assign_locale}
      ] do
      live "/users/confirm/:token", UserConfirmationLive, :edit
      live "/users/confirm", UserConfirmationInstructionsLive, :new
    end

    # Public resume route
    live "/resumes/:id", Resume.IndexLive, :show
  end
end
