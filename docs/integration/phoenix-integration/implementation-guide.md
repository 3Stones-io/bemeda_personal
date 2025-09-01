# Phoenix Integration Implementation Guide

This guide provides step-by-step instructions for integrating the USE scenario system with the existing Phoenix application.

## 🎯 Overview

The Phoenix app already implements ~80% of the S001 Healthcare Recruitment scenario. This guide shows how to:

1. Create API endpoints for USE scenario testing
2. Bridge USE scenarios with existing Phoenix contexts
3. Add missing scenario components
4. Set up real-time scenario monitoring

## 📋 Prerequisites

- Phoenix app running locally (`mix phx.server`)
- USE scenario system set up (Python + GitHub)
- Database seeded with test data

## 🔧 Step 1: API Integration Layer

### Create USE API Controllers

**File: `lib/bemeda_personal_web/controllers/use/scenario_controller.ex`**

```elixir
defmodule BemedaPersonalWeb.USE.ScenarioController do
  use BemedaPersonalWeb, :controller
  
  alias BemedaPersonal.USE.ScenarioBridge
  alias BemedaPersonal.{Accounts, Companies, JobPostings, JobApplications}

  @doc """
  Execute a USE scenario with given parameters
  POST /api/use/scenarios/:scenario_id/execute
  """
  def execute(conn, %{"scenario_id" => scenario_id} = params) do
    case scenario_id do
      "B_S001_US001" -> execute_organisation_receives_cold_call(conn, params)
      "B_S001_US002" -> execute_discuss_staffing_needs(conn, params)
      "B_S001_US003" -> execute_agree_to_job_posting(conn, params)
      "B_S001_US004" -> execute_review_candidates(conn, params)
      "B_S001_US007" -> execute_jobseeker_creates_profile(conn, params)
      "B_S001_US009" -> execute_review_and_apply(conn, params)
      _ -> 
        conn
        |> put_status(:not_found)
        |> json(%{error: "Scenario not found: #{scenario_id}"})
    end
  end

  @doc """
  Get scenario execution status
  GET /api/use/scenarios/:scenario_id/status
  """
  def status(conn, %{"scenario_id" => scenario_id}) do
    # Query current state from database
    status_data = ScenarioBridge.get_scenario_status(scenario_id)
    
    json(conn, %{
      scenario_id: scenario_id,
      status: status_data.status,
      actors: status_data.actors,
      last_updated: status_data.updated_at,
      metadata: status_data.metadata
    })
  end

  # Private scenario implementations

  defp execute_organisation_receives_cold_call(conn, params) do
    # Given: A Healthcare Organisation exists as a qualified prospect
    with {:ok, org_data} <- validate_organisation_data(params),
         {:ok, organisation} <- find_or_create_organisation(org_data) do
      
      # When: The Sales Team calls the Healthcare Organisation
      ScenarioBridge.broadcast_scenario_event("B_S001_US001", :sales_call_initiated, %{
        organisation_id: organisation.id,
        timestamp: DateTime.utc_now()
      })
      
      # Then: The Healthcare Organisation should understand our value proposition
      result = %{
        status: "success",
        organisation_id: organisation.id,
        next_actions: ["schedule_follow_up", "prepare_proposal"],
        actors: %{
          organisation: %{
            id: organisation.id,
            name: organisation.name,
            engagement_level: "interested"
          },
          sales_team: %{
            call_completed: true,
            follow_up_scheduled: true
          }
        }
      }
      
      ScenarioBridge.broadcast_scenario_event("B_S001_US001", :scenario_completed, result)
      json(conn, result)
    else
      {:error, reason} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{error: reason})
    end
  end

  defp execute_jobseeker_creates_profile(conn, params) do
    # Given: A job seeker wants to create a profile
    with {:ok, user_data} <- validate_jobseeker_data(params),
         {:ok, user} <- Accounts.register_job_seeker(user_data),
         {:ok, _resume} <- create_initial_resume(user) do
      
      ScenarioBridge.broadcast_scenario_event("B_S001_US007", :profile_created, %{
        user_id: user.id,
        profile_completeness: calculate_profile_completeness(user)
      })
      
      json(conn, %{
        status: "success",
        user_id: user.id,
        profile_url: "/resume/#{user.id}",
        completeness: calculate_profile_completeness(user)
      })
    else
      {:error, %Ecto.Changeset{} = changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{errors: format_changeset_errors(changeset)})
    end
  end

  # Helper functions
  
  defp validate_organisation_data(params) do
    required_fields = ["name", "industry", "location", "admin_email"]
    
    case Enum.all?(required_fields, &Map.has_key?(params, &1)) do
      true -> {:ok, params}
      false -> {:error, "Missing required fields: #{inspect(required_fields)}"}
    end
  end

  defp find_or_create_organisation(%{"name" => name, "admin_email" => email} = data) do
    case Companies.get_company_by_name(name) do
      nil -> create_new_organisation(data)
      company -> {:ok, company}
    end
  end

  defp create_new_organisation(data) do
    # Create admin user first
    user_attrs = %{
      email: data["admin_email"],
      first_name: data["first_name"] || "Admin",
      last_name: data["last_name"] || "User",
      password: "TempPassword123!",
      user_type: :employer
    }

    with {:ok, admin_user} <- Accounts.register_employer(user_attrs),
         {:ok, company} <- Companies.create_company(%{
           name: data["name"],
           industry: data["industry"],
           location: data["location"],
           admin_user_id: admin_user.id
         }) do
      {:ok, company}
    end
  end

  defp calculate_profile_completeness(user) do
    # Basic completeness calculation
    fields = [:first_name, :last_name, :email]
    completed = Enum.count(fields, &(Map.get(user, &1) != nil))
    round(completed / length(fields) * 100)
  end
end
```

### Create Actor Controller

**File: `lib/bemeda_personal_web/controllers/use/actor_controller.ex`**

```elixir
defmodule BemedaPersonalWeb.USE.ActorController do
  use BemedaPersonalWeb, :controller
  
  alias BemedaPersonal.{Accounts, Companies, JobPostings}
  alias BemedaPersonal.USE.ScenarioBridge

  @doc """
  Set up a specific actor type for scenario testing
  POST /api/use/actors/:actor_type/setup
  """
  def setup(conn, %{"actor_type" => actor_type} = params) do
    case actor_type do
      "healthcare_organisation" -> setup_healthcare_organisation(conn, params)
      "job_seeker" -> setup_job_seeker(conn, params)
      "sales_team" -> setup_sales_team(conn, params)
      _ -> 
        conn
        |> put_status(:not_found)
        |> json(%{error: "Unknown actor type: #{actor_type}"})
    end
  end

  defp setup_healthcare_organisation(conn, params) do
    org_data = %{
      "name" => params["name"] || "Test Hospital #{System.unique_integer()}",
      "industry" => "Healthcare",
      "location" => params["location"] || "Zurich, Switzerland",
      "admin_email" => params["admin_email"] || "admin-#{System.unique_integer()}@test-hospital.com",
      "first_name" => params["first_name"] || "Test",
      "last_name" => params["last_name"] || "Admin"
    }

    case create_new_organisation(org_data) do
      {:ok, company} ->
        ScenarioBridge.broadcast_scenario_event("actor_setup", :organisation_created, %{
          company_id: company.id,
          actor_type: "healthcare_organisation"
        })
        
        json(conn, %{
          status: "success",
          actor_id: company.id,
          actor_type: "healthcare_organisation",
          details: %{
            name: company.name,
            admin_user_id: company.admin_user_id
          }
        })
      
      {:error, reason} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{error: reason})
    end
  end

  defp setup_job_seeker(conn, params) do
    seeker_data = %{
      email: params["email"] || "jobseeker-#{System.unique_integer()}@example.com",
      first_name: params["first_name"] || "Jane",
      last_name: params["last_name"] || "Doe",
      password: "TestPassword123!",
      user_type: :job_seeker
    }

    case Accounts.register_job_seeker(seeker_data) do
      {:ok, user} ->
        # Create initial resume
        {:ok, _resume} = create_initial_resume(user)
        
        ScenarioBridge.broadcast_scenario_event("actor_setup", :job_seeker_created, %{
          user_id: user.id,
          actor_type: "job_seeker"
        })
        
        json(conn, %{
          status: "success",
          actor_id: user.id,
          actor_type: "job_seeker",
          details: %{
            email: user.email,
            full_name: "#{user.first_name} #{user.last_name}"
          }
        })
      
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{errors: format_changeset_errors(changeset)})
    end
  end

  # Helper functions (same as in scenario_controller.ex)
end
```

## 🔧 Step 2: Scenario Event Bridge

**File: `lib/bemeda_personal/use/scenario_bridge.ex`**

```elixir
defmodule BemedaPersonal.USE.ScenarioBridge do
  @moduledoc """
  Bridge between USE scenarios and Phoenix application events.
  Provides real-time scenario execution monitoring and state management.
  """
  
  alias Phoenix.PubSub
  alias BemedaPersonal.Repo
  
  @pubsub BemedaPersonal.PubSub

  @doc """
  Broadcast a scenario event to all subscribers
  """
  def broadcast_scenario_event(scenario_id, event_type, data) do
    event_data = %{
      scenario_id: scenario_id,
      event_type: event_type,
      data: data,
      timestamp: DateTime.utc_now(),
      session_id: get_session_id()
    }
    
    # Broadcast to scenario-specific topic
    PubSub.broadcast(@pubsub, "use_scenario:#{scenario_id}", event_data)
    
    # Broadcast to general USE topic
    PubSub.broadcast(@pubsub, "use_scenarios", event_data)
    
    # Store event for status queries
    store_scenario_event(event_data)
    
    event_data
  end

  @doc """
  Subscribe to scenario events
  """
  def subscribe_to_scenario(scenario_id) do
    PubSub.subscribe(@pubsub, "use_scenario:#{scenario_id}")
  end

  def subscribe_to_all_scenarios do
    PubSub.subscribe(@pubsub, "use_scenarios")
  end

  @doc """
  Get current status of a scenario
  """
  def get_scenario_status(scenario_id) do
    # This could be implemented with a GenServer or database table
    # For now, return a basic structure
    %{
      scenario_id: scenario_id,
      status: "ready",
      actors: get_scenario_actors(scenario_id),
      last_event: get_last_event(scenario_id),
      updated_at: DateTime.utc_now(),
      metadata: %{}
    }
  end

  # Private functions
  
  defp get_session_id do
    Process.get(:use_scenario_session_id, UUID.uuid4())
  end

  defp store_scenario_event(event_data) do
    # Store in ETS table or database for status queries
    # Implementation depends on persistence requirements
    :ok
  end

  defp get_scenario_actors(scenario_id) do
    case scenario_id do
      "B_S001_US001" -> ["healthcare_organisation", "sales_team"]
      "B_S001_US007" -> ["job_seeker"]
      "B_S001_US009" -> ["job_seeker", "healthcare_organisation"]
      _ -> []
    end
  end

  defp get_last_event(scenario_id) do
    # Retrieve last event from storage
    nil
  end
end
```

## 🔧 Step 3: Router Configuration

**Add to `lib/bemeda_personal_web/router.ex`:**

```elixir
# Add USE API scope
scope "/api/use", BemedaPersonalWeb.USE do
  pipe_through :api
  
  # Scenario management
  post "/scenarios/:scenario_id/execute", ScenarioController, :execute
  get "/scenarios/:scenario_id/status", ScenarioController, :status
  
  # Actor setup for testing
  post "/actors/:actor_type/setup", ActorController, :setup
  get "/actors/:actor_type/list", ActorController, :list
  
  # Real-time scenario monitoring
  get "/events/stream", EventController, :stream
end
```

## 🔧 Step 4: USE Test Data Seeds

**File: `priv/repo/use_seeds.exs`**

```elixir
# USE Scenario Test Data Seeds
# Run with: mix run priv/repo/use_seeds.exs

alias BemedaPersonal.{Repo, Accounts, Companies, JobPostings}

defmodule USESeeds do
  def run do
    IO.puts("🎭 Setting up USE scenario test data...")
    
    # Clean existing test data
    clean_test_data()
    
    # Create S001 scenario actors
    {:ok, actors} = create_s001_actors()
    
    # Create test job postings
    {:ok, jobs} = create_test_jobs(actors.healthcare_org)
    
    # Create test applications
    create_test_applications(actors.job_seeker, jobs)
    
    IO.puts("✅ USE scenario test data created successfully!")
    IO.inspect(actors, label: "Created Actors")
  end

  defp clean_test_data do
    # Remove test data (be careful in production!)
    from(u in "users", where: like(u.email, "%@test-%")) |> Repo.delete_all()
    from(c in "companies", where: like(c.name, "Test Hospital%")) |> Repo.delete_all()
  end

  defp create_s001_actors do
    # Healthcare Organisation (US001-006, US013-018)
    {:ok, healthcare_admin} = Accounts.register_employer(%{
      email: "admin@test-hospital.com",
      first_name: "Dr. Sarah",
      last_name: "Johnson",
      password: "TestPassword123!",
      confirmed_at: DateTime.utc_now()
    })

    {:ok, healthcare_org} = Companies.create_company(%{
      name: "Test Hospital Zurich",
      description: "Leading healthcare provider in Zurich",
      industry: "Healthcare",
      size: "500-1000",
      location: "Zurich, Switzerland",
      website_url: "https://test-hospital.com",
      admin_user_id: healthcare_admin.id
    })

    # Job Seeker (US007-012)
    {:ok, job_seeker} = Accounts.register_job_seeker(%{
      email: "nurse@test-candidate.com",
      first_name: "Maria",
      last_name: "Rodriguez",
      password: "TestPassword123!",
      gender: :female,
      locale: :en,
      confirmed_at: DateTime.utc_now()
    })

    # Create resume for job seeker
    {:ok, resume} = BemedaPersonal.Resumes.create_resume(%{
      user_id: job_seeker.id,
      headline: "Experienced ICU Nurse",
      summary: "5+ years of critical care nursing experience",
      contact_email: job_seeker.email,
      is_public: true
    })

    {:ok, %{
      healthcare_org: healthcare_org,
      healthcare_admin: healthcare_admin,
      job_seeker: job_seeker,
      resume: resume
    }}
  end

  defp create_test_jobs(company) do
    jobs = [
      %{
        title: "ICU Nurse - Night Shift",
        description: "We are seeking an experienced ICU nurse for night shift positions...",
        location: "Zurich, Switzerland",
        employment_type: "full-time",
        salary_min: 75000,
        salary_max: 95000,
        currency: "CHF",
        remote_allowed: false,
        profession: "nursing",
        company_id: company.id
      },
      %{
        title: "Emergency Room Physician",
        description: "Join our dynamic ER team...",
        location: "Zurich, Switzerland", 
        employment_type: "full-time",
        salary_min: 120000,
        salary_max: 150000,
        currency: "CHF",
        remote_allowed: false,
        profession: "physician",
        company_id: company.id
      }
    ]

    created_jobs = Enum.map(jobs, fn job_attrs ->
      {:ok, job} = JobPostings.create_job_posting(job_attrs)
      job
    end)

    {:ok, created_jobs}
  end

  defp create_test_applications(job_seeker, jobs) do
    # Apply to the ICU nurse position
    icu_job = Enum.find(jobs, &(&1.title =~ "ICU Nurse"))
    
    {:ok, _application} = BemedaPersonal.JobApplications.create_application(%{
      job_posting_id: icu_job.id,
      user_id: job_seeker.id,
      cover_letter: "I am very interested in this ICU position..."
    })
  end
end

# Run the seeds
USESeeds.run()
```

## 🔧 Step 5: Elixir USE Tests

**File: `test/use_scenarios/business_scenarios_test.exs`**

```elixir
defmodule BemedaPersonal.USEScenarios.BusinessScenariosTest do
  use BemedaPersonal.DataCase
  use BemedaPersonalWeb.ConnCase

  alias BemedaPersonal.USE.ScenarioBridge
  alias BemedaPersonal.{Accounts, Companies}

  describe "B_S001: Cold Call to Placement Scenario" do
    setup do
      # Subscribe to scenario events
      ScenarioBridge.subscribe_to_all_scenarios()
      
      # Create test API connection
      conn = build_conn()
      |> put_req_header("content-type", "application/json")
      
      {:ok, conn: conn}
    end

    test "US001: Organisation Receives Cold Call", %{conn: conn} do
      # Given: A Healthcare Organisation exists as a qualified prospect
      org_params = %{
        "name" => "Test Medical Center",
        "industry" => "Healthcare", 
        "location" => "Basel, Switzerland",
        "admin_email" => "admin@test-medical.com",
        "first_name" => "Dr. Hans",
        "last_name" => "Mueller"
      }

      # When: The scenario is executed
      response = post(conn, "/api/use/scenarios/B_S001_US001/execute", org_params)
      result = json_response(response, 200)

      # Then: The organisation should be successfully engaged
      assert result["status"] == "success"
      assert result["organisation_id"] != nil
      assert result["actors"]["organisation"]["engagement_level"] == "interested"
      assert result["actors"]["sales_team"]["call_completed"] == true

      # And: The appropriate events should be broadcast
      assert_received %{
        scenario_id: "B_S001_US001",
        event_type: :sales_call_initiated,
        data: %{organisation_id: org_id}
      }
      
      assert_received %{
        scenario_id: "B_S001_US001", 
        event_type: :scenario_completed,
        data: %{status: "success"}
      }

      # Verify organisation was created
      company = Companies.get_company!(org_id)
      assert company.name == "Test Medical Center"
    end

    test "US007: JobSeeker Creates Profile", %{conn: conn} do
      # Given: A job seeker wants to create a profile
      seeker_params = %{
        "email" => "nurse@example.com",
        "first_name" => "Anna",
        "last_name" => "Smith",
        "password" => "TestPassword123!"
      }

      # When: The profile creation scenario is executed
      response = post(conn, "/api/use/scenarios/B_S001_US007/execute", seeker_params)
      result = json_response(response, 200)

      # Then: The profile should be created successfully
      assert result["status"] == "success"
      assert result["user_id"] != nil
      assert result["profile_url"] != nil
      assert result["completeness"] > 0

      # And: The user should exist in the database
      user = Accounts.get_user!(result["user_id"])
      assert user.email == "nurse@example.com"
      assert user.user_type == :job_seeker

      # And: Profile creation event should be broadcast
      assert_received %{
        scenario_id: "B_S001_US007",
        event_type: :profile_created,
        data: %{user_id: user_id}
      }
    end

    test "US009: Review and Apply to Job", %{conn: conn} do
      # Given: A job seeker exists and there are job postings
      {:ok, job_seeker} = create_test_job_seeker()
      {:ok, company} = create_test_company()
      {:ok, job_posting} = create_test_job_posting(company)

      application_params = %{
        "job_seeker_id" => job_seeker.id,
        "job_posting_id" => job_posting.id,
        "cover_letter" => "I am very interested in this position..."
      }

      # When: The application scenario is executed
      response = post(conn, "/api/use/scenarios/B_S001_US009/execute", application_params)
      result = json_response(response, 200)

      # Then: The application should be submitted successfully
      assert result["status"] == "success"
      assert result["application_id"] != nil
      assert result["application_state"] == "applied"

      # And: The application should exist in the database
      application = BemedaPersonal.JobApplications.get_application!(result["application_id"])
      assert application.state == "applied"
      assert application.user_id == job_seeker.id
      assert application.job_posting_id == job_posting.id
    end
  end

  # Helper functions for test data creation
  defp create_test_job_seeker do
    Accounts.register_job_seeker(%{
      email: "test-seeker@example.com",
      first_name: "Test",
      last_name: "Seeker",
      password: "TestPassword123!"
    })
  end

  defp create_test_company do
    {:ok, admin} = Accounts.register_employer(%{
      email: "admin@test-company.com",
      first_name: "Test",
      last_name: "Admin",
      password: "TestPassword123!"
    })

    Companies.create_company(%{
      name: "Test Healthcare Company",
      industry: "Healthcare",
      location: "Zurich",
      admin_user_id: admin.id
    })
  end

  defp create_test_job_posting(company) do
    BemedaPersonal.JobPostings.create_job_posting(%{
      title: "Test Nurse Position",
      description: "Test nursing position",
      location: "Zurich",
      employment_type: "full-time",
      company_id: company.id,
      profession: "nursing"
    })
  end
end
```

## 🚀 Step 6: Running the Integration

### 1. Set up the API endpoints:
```bash
# Add controllers to Phoenix app
cp controllers/use/* lib/bemeda_personal_web/controllers/use/

# Update router with USE routes
# (Add router configuration from Step 3)
```

### 2. Create test data:
```bash
# Run USE scenario seeds
mix run priv/repo/use_seeds.exs
```

### 3. Test the integration:
```bash
# Run Elixir USE tests
mix test test/use_scenarios/

# Test API endpoints manually
curl -X POST http://localhost:4000/api/use/scenarios/B_S001_US001/execute \
  -H "Content-Type: application/json" \
  -d '{"name": "Test Hospital", "admin_email": "admin@test.com"}'
```

### 4. Connect Python USE tests:
```python
# Update Python step definitions to call Phoenix API
@when('the Sales Team calls the Healthcare Organisation')
def step_sales_team_calls_organisation(context):
    response = context.api_client.post(
        "/api/use/scenarios/B_S001_US001/execute",
        json={
            "name": context.healthcare_org.name,
            "admin_email": context.healthcare_org.admin_email
        }
    )
    context.scenario_response = response.json()
```

## 📊 Next Steps

1. **Complete Missing Scenarios**: Implement US005 (interviews), US008 (job matching), US013-018 (sales team)
2. **Real-time Monitoring**: Add LiveView components to visualize scenario execution
3. **Performance Optimization**: Add indexes and optimize queries for scenario data
4. **Production Deployment**: Set up monitoring and logging for scenario execution

This integration bridges the USE scenario documentation with the production Phoenix application, creating a living system where scenarios are both documented and executable.