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

  # PUBLIC ROUTES (no authentication required)
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

  # UNAUTHENTICATED ROUTES (redirect if already logged in)
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

  # JOB SEEKER ONLY ROUTES
  scope "/", BemedaPersonalWeb do
    pipe_through [
      :browser,
      :require_authenticated_user,
      :require_job_seeker_user_type
    ]

    live_session :job_seeker_routes,
      on_mount: [
        {BemedaPersonalWeb.UserAuth, :ensure_authenticated},
        {BemedaPersonalWeb.UserAuth, :require_job_seeker_user_type},
        {BemedaPersonalWeb.LiveHelpers, :assign_locale}
      ] do
      # Resume management (job seekers only)
      live "/resume", Resume.ShowLive, :show
      live "/resume/edit", Resume.ShowLive, :edit_resume
      live "/resume/education/new", Resume.ShowLive, :new_education
      live "/resume/education/:id/edit", Resume.ShowLive, :edit_education
      live "/resume/work-experience/new", Resume.ShowLive, :new_work_experience
      live "/resume/work-experience/:id/edit", Resume.ShowLive, :edit_work_experience

      # Job applications (job seekers only)
      live "/job_applications", JobApplicationLive.Index, :index
      live "/jobs/:job_id/job_applications/new", JobApplicationLive.Index, :new

      # Job application modal route
      live "/jobs/:id/apply", JobLive.Show, :apply
    end
  end

  # EMPLOYER ONLY ROUTES
  scope "/company", BemedaPersonalWeb do
    pipe_through [
      :browser,
      :require_authenticated_user,
      :require_employer_user_type
    ]

    # Company creation/management routes (no company required)
    live_session :company_creation,
      on_mount: [
        {BemedaPersonalWeb.UserAuth, :ensure_authenticated},
        {BemedaPersonalWeb.UserAuth, :require_employer_user_type},
        {BemedaPersonalWeb.LiveHelpers, :assign_locale}
      ] do
      live "/", CompanyLive.Index, :index
      live "/new", CompanyLive.Index, :new
      live "/edit", CompanyLive.Index, :edit
    end

    # Company-specific routes (require existing company)
    live_session :company_operations,
      on_mount: [
        {BemedaPersonalWeb.UserAuth, :ensure_authenticated},
        {BemedaPersonalWeb.UserAuth, :require_employer_user_type},
        {BemedaPersonalWeb.UserAuth, :require_user_company},
        {BemedaPersonalWeb.LiveHelpers, :assign_locale}
      ] do
      # Job management
      live "/jobs", CompanyJobLive.Index, :index
      live "/jobs/new", CompanyJobLive.New, :new
      live "/jobs/:id", CompanyJobLive.Show, :show
      live "/jobs/:id/edit", CompanyJobLive.Edit, :edit

      # Applicant management
      live "/applicants", CompanyApplicantLive.Index, :index
      live "/applicants/:job_id", CompanyApplicantLive.Index, :index
      live "/applicant/:id", CompanyApplicantLive.Show, :show
    end
  end

  # SHARED AUTHENTICATED ROUTES (both user types)
  scope "/", BemedaPersonalWeb do
    pipe_through [:browser, :require_authenticated_user]

    live_session :shared_authenticated_routes,
      on_mount: [
        {BemedaPersonalWeb.UserAuth, :ensure_authenticated},
        {BemedaPersonalWeb.LiveHelpers, :assign_locale}
      ] do
      live "/users/settings", UserSettingsLive.Index, :index
      live "/users/settings/info", UserSettingsLive.Info, :view
      live "/users/settings/password", UserSettingsLive.Password, :edit
      live "/users/settings/confirm_email/:token", UserSettingsLive.Info, :confirm_email
      live "/notifications", NotificationLive.Index, :index
      live "/notifications/:id", NotificationLive.Show, :show
      live "/jobs/:job_id/job_applications/:id", JobApplicationLive.Show, :show
      live "/jobs/:job_id/job_applications/:id/history", JobApplicationLive.History, :show
    end
  end

  # UTILITY ROUTES (no authentication required)
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

  # Health check route
  resources "/health", BemedaPersonalWeb.HealthController, only: [:index]

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
end
