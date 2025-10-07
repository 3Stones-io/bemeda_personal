defmodule BemedaPersonalWeb.Features.CompanyProfileSteps do
  use Cucumber.StepDefinition
  use BemedaPersonalWeb, :verified_routes

  import BemedaPersonal.BddHelpers
  import ExUnit.Assertions
  import Phoenix.ConnTest
  import Phoenix.LiveViewTest

  alias BemedaPersonal.Accounts.Scope
  alias BemedaPersonal.AccountsFixtures
  alias BemedaPersonal.Companies
  alias BemedaPersonal.CompaniesFixtures
  alias BemedaPersonalWeb.Endpoint

  @endpoint Endpoint

  @type context :: map()

  # ============================================================================
  # Given Steps - Company Profile Setup
  # ============================================================================

  step "I am on the company dashboard", context do
    conn = context.conn

    {:ok, view, _html} = live(conn, ~p"/company")

    {:ok, Map.put(context, :view, view)}
  end

  step "I am on the company edit page", context do
    conn = context.conn

    {:ok, view, _html} = live(conn, ~p"/company/edit")

    {:ok, Map.put(context, :view, view)}
  end

  step "there is a company with public profile", context do
    employer =
      AccountsFixtures.user_fixture(%{
        user_type: :employer,
        confirmed_at: DateTime.utc_now(),
        email: generate_unique_email("public_employer")
      })

    company =
      CompaniesFixtures.company_fixture(employer, %{
        name: "Public Medical Center",
        description: "A public healthcare provider",
        location: "Basel, Switzerland"
      })

    {:ok, Map.put(context, :public_company, company)}
  end

  # ============================================================================
  # When Steps - Company Profile Actions
  # ============================================================================

  step "I visit the company dashboard", context do
    conn = context.conn

    {:ok, view, _html} = live(conn, ~p"/company")

    {:ok, Map.put(context, :view, view)}
  end

  step "I visit the public company page", context do
    conn = context.conn
    company = context.public_company

    {:ok, view, _html} = live(conn, ~p"/companies/#{company}")

    {:ok, Map.put(context, :view, view)}
  end

  step "I fill in company name with {string}", %{args: [name]} = context do
    form_data = Map.get(context, :form_data, %{})
    {:ok, Map.put(context, :form_data, Map.put(form_data, :name, name))}
  end

  step "I fill in company description with {string}", %{args: [description]} = context do
    form_data = Map.get(context, :form_data, %{})
    {:ok, Map.put(context, :form_data, Map.put(form_data, :description, description))}
  end

  step "I fill in company location with {string}", %{args: [location]} = context do
    form_data = Map.get(context, :form_data, %{})
    {:ok, Map.put(context, :form_data, Map.put(form_data, :location, location))}
  end

  step "I fill in company website with {string}", %{args: [website]} = context do
    form_data = Map.get(context, :form_data, %{})
    {:ok, Map.put(context, :form_data, Map.put(form_data, :website_url, website))}
  end

  step "I fill in company phone with {string}", %{args: [phone]} = context do
    form_data = Map.get(context, :form_data, %{})
    {:ok, Map.put(context, :form_data, Map.put(form_data, :phone_number, phone))}
  end

  step "I submit the company form", context do
    view = context.view
    form_data = Map.get(context, :form_data, %{})

    # Submit the LiveComponent form (it has phx-target={@myself})
    # First trigger validation, then submit
    view
    |> form("#company-form", %{company: form_data})
    |> render_change()

    view
    |> form("#company-form", %{company: form_data})
    |> render_submit()

    # To ensure we see the updated data, navigate to the company dashboard explicitly
    # This guarantees a fresh load of the company data from the database
    {:ok, updated_view, html} = live(context.conn, ~p"/company")

    context
    |> Map.put(:view, updated_view)
    |> Map.put(:last_html, html)
    |> then(&{:ok, &1})
  end

  # ============================================================================
  # Then Steps - Company Profile Assertions
  # ============================================================================

  step "I should see the company name", context do
    view = context.view
    # Prioritize :public_company for public view scenarios
    company = Map.get(context, :public_company) || Map.get(context, :company)

    html = render(view)
    assert html =~ company.name, "Expected to see company name '#{company.name}' in the page"

    {:ok, context}
  end

  step "I should see the company description", context do
    view = context.view
    # Prioritize :public_company for public view scenarios
    company = Map.get(context, :public_company) || Map.get(context, :company)

    html = render(view)

    assert html =~ company.description,
           "Expected to see company description '#{company.description}' in the page"

    {:ok, context}
  end

  step "I should see the company location", context do
    html = render(context.view)
    # Prioritize :public_company for public view scenarios
    company = Map.get(context, :public_company) || Map.get(context, :company)

    assert html =~ company.location

    {:ok, context}
  end

  step "the company profile should be updated", context do
    form_data = context.form_data
    company = context.company
    user = context.current_user

    scope = Scope.for_user(user) |> Scope.put_company(company)
    updated_company = Companies.get_company!(scope, company.id)

    if Map.has_key?(form_data, :name) do
      assert updated_company.name == form_data.name
    end

    if Map.has_key?(form_data, :description) do
      assert updated_company.description == form_data.description
    end

    if Map.has_key?(form_data, :location) do
      assert updated_company.location == form_data.location
    end

    {:ok, context}
  end
end
