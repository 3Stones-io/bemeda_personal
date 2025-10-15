defmodule BemedaPersonalWeb.Router do
  use BemedaPersonalWeb, :router

  import BemedaPersonalWeb.UserAuth
  import PhoenixStorybook.Router

  alias BemedaPersonalWeb.AdminAuth
  alias BemedaPersonalWeb.Locale

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {BemedaPersonalWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_scope_for_user
    plug Locale
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :admin do
    plug :browser
    plug AdminAuth
    plug Locale
  end

  # PUBLIC ROUTES (no authentication required)
  scope "/", BemedaPersonalWeb do
    pipe_through [:browser, :assign_current_scope, :require_user_profile]

    get "/", PageController, :home

    live_session :public_routes,
      on_mount:
        Enum.filter(
          [
            if(Application.compile_env(:bemeda_personal, :sql_sandbox),
              do: {BemedaPersonalWeb.LiveAcceptance, :default}
            ),
            {BemedaPersonalWeb.UserAuth, :assign_current_scope},
            {BemedaPersonalWeb.UserAuth, :require_user_profile},
            {BemedaPersonalWeb.LiveHelpers, :assign_locale}
          ],
          & &1
        ) do
      live "/jobs", JobLive.Index, :index
      live "/jobs/:id", JobLive.Show, :show
      live "/companies/:id", CompanyPublicLive.Show, :show
      live "/companies/:id/jobs", CompanyPublicLive.Jobs, :jobs
    end
  end

  # UNAUTHENTICATED ROUTES (redirect if already logged in)
  scope "/users", BemedaPersonalWeb do
    pipe_through [:browser, :assign_current_scope]

    live_session :redirect_if_user_is_authenticated,
      on_mount:
        Enum.filter(
          [
            if(Application.compile_env(:bemeda_personal, :sql_sandbox),
              do: {BemedaPersonalWeb.LiveAcceptance, :default}
            ),
            {BemedaPersonalWeb.UserAuth, :redirect_if_user_is_authenticated},
            {BemedaPersonalWeb.UserAuth, :assign_current_scope},
            {BemedaPersonalWeb.LiveHelpers, :assign_locale}
          ],
          & &1
        ) do
      live "/register", UserLive.Registration, :new
      live "/log_in", UserLive.Login, :new
    end

    post "/log_in", UserSessionController, :create
    get "/log_in/:token", UserSessionController, :create_from_token
  end

  # JOB SEEKER ONLY ROUTES
  scope "/", BemedaPersonalWeb do
    pipe_through [
      :browser,
      :require_authenticated_user,
      :require_job_seeker_user_type,
      :require_user_profile
    ]

    live_session :job_seeker_routes,
      on_mount:
        Enum.filter(
          [
            if(Application.compile_env(:bemeda_personal, :sql_sandbox),
              do: {BemedaPersonalWeb.LiveAcceptance, :default}
            ),
            {BemedaPersonalWeb.UserAuth, :require_authenticated},
            {BemedaPersonalWeb.UserAuth, :require_job_seeker_user_type},
            {BemedaPersonalWeb.UserAuth, :require_user_profile},
            {BemedaPersonalWeb.LiveHelpers, :assign_locale}
          ],
          & &1
        ) do
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

  scope "/", BemedaPersonalWeb do
    pipe_through [
      :browser,
      :require_authenticated_user,
      :require_job_seeker_user_type
    ]

    live_session :job_seeker_profile_routes,
      on_mount:
        Enum.filter(
          [
            if(Application.compile_env(:bemeda_personal, :sql_sandbox),
              do: {BemedaPersonalWeb.LiveAcceptance, :default}
            ),
            {BemedaPersonalWeb.UserAuth, :require_authenticated},
            {BemedaPersonalWeb.UserAuth, :require_job_seeker_user_type},
            {BemedaPersonalWeb.UserAuth, :redirect_if_profile_complete},
            {BemedaPersonalWeb.LiveHelpers, :assign_locale}
          ],
          & &1
        ) do
      live "/users/profile", UserLive.Index, :index
      live "/users/profile/employment_type", UserLive.Index, :edit_employment_type
      live "/users/profile/medical_role", UserLive.Index, :edit_medical_role
      live "/users/profile/bio", UserLive.Index, :edit_bio
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
      on_mount:
        Enum.filter(
          [
            if(Application.compile_env(:bemeda_personal, :sql_sandbox),
              do: {BemedaPersonalWeb.LiveAcceptance, :default}
            ),
            {BemedaPersonalWeb.UserAuth, :require_authenticated},
            {BemedaPersonalWeb.UserAuth, :require_employer_user_type},
            {BemedaPersonalWeb.LiveHelpers, :assign_locale}
          ],
          & &1
        ) do
      live "/new", CompanyLive.Index, :new
    end

    # Company-specific routes (require existing company)
    live_session :company_operations,
      on_mount:
        Enum.filter(
          [
            if(Application.compile_env(:bemeda_personal, :sql_sandbox),
              do: {BemedaPersonalWeb.LiveAcceptance, :default}
            ),
            {BemedaPersonalWeb.UserAuth, :require_authenticated},
            {BemedaPersonalWeb.UserAuth, :require_employer_user_type},
            {BemedaPersonalWeb.UserAuth, :require_user_company},
            {BemedaPersonalWeb.LiveHelpers, :assign_locale}
          ],
          & &1
        ) do
      # company info management
      live "/", CompanyLive.Index, :index
      live "/edit", CompanyLive.Index, :edit

      # Job management
      live "/jobs", CompanyJobLive.Index, :index
      live "/jobs/new", CompanyJobLive.New, :new
      live "/jobs/:id", CompanyJobLive.Show, :show
      live "/jobs/:id/edit", CompanyJobLive.Edit, :edit
      live "/jobs/:id/review", CompanyJobLive.Review, :new

      # Applicant management
      live "/applicants", CompanyApplicantLive.Index, :index
      live "/applicants/:job_id", CompanyApplicantLive.Index, :index
      live "/applicant/:id", CompanyApplicantLive.Show, :show
    end
  end

  # SHARED AUTHENTICATED ROUTES (both user types)
  scope "/", BemedaPersonalWeb do
    pipe_through [:browser, :require_authenticated_user, :require_user_profile]

    live_session :shared_authenticated_routes,
      on_mount:
        Enum.filter(
          [
            if(Application.compile_env(:bemeda_personal, :sql_sandbox),
              do: {BemedaPersonalWeb.LiveAcceptance, :default}
            ),
            {BemedaPersonalWeb.UserAuth, :require_authenticated},
            {BemedaPersonalWeb.UserAuth, :require_user_profile},
            {BemedaPersonalWeb.LiveHelpers, :assign_locale}
          ],
          & &1
        ) do
      live "/notifications", NotificationLive.Index, :index
      live "/notifications/:id", NotificationLive.Show, :show
      live "/jobs/:job_id/job_applications/:id", JobApplicationLive.Show, :show
      live "/jobs/:job_id/job_applications/:id/history", JobApplicationLive.History, :show
      live "/users/settings", UserLive.Settings, :edit
      live "/users/settings/confirm-email/:token", UserLive.Settings, :confirm_email
    end

    post "/users/update_password", UserSessionController, :update_password
  end

  # UTILITY ROUTES (no authentication required)
  scope "/", BemedaPersonalWeb do
    pipe_through [:browser]

    get "/locale/:locale", LocaleController, :set
    delete "/users/log_out", UserSessionController, :delete

    # Public resume route
    live "/resumes/:id", Resume.IndexLive, :show
  end

  # ADMIN ROUTES
  scope "/admin", BemedaPersonalWeb do
    pipe_through :admin

    live_session :admin,
      layout: {BemedaPersonalWeb.Layouts, :admin},
      on_mount:
        Enum.filter(
          [
            if(Application.compile_env(:bemeda_personal, :sql_sandbox),
              do: {BemedaPersonalWeb.LiveAcceptance, :default}
            ),
            {BemedaPersonalWeb.LiveHelpers, :assign_locale}
          ],
          & &1
        ) do
      live "/", AdminLive.Dashboard, :index
      live "/invitations/new", AdminLive.InvitationNew, :new
    end
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

  # Storybook assets (must be outside browser pipeline - no CSRF protection)
  scope "/" do
    storybook_assets()
  end

  # Public Storybook route (can be accessed without authentication)
  scope "/" do
    pipe_through :browser

    live_storybook("/storybook", backend_module: BemedaPersonalWeb.Storybook)
  end
end
