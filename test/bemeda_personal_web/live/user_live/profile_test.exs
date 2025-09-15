defmodule BemedaPersonalWeb.UserLive.ProfileTest do
  use BemedaPersonalWeb.ConnCase, async: true

  import BemedaPersonal.AccountsFixtures
  import Phoenix.LiveViewTest

  alias BemedaPersonal.Accounts

  describe "Profile page rendering" do
    setup :register_and_log_in_user

    test "renders profile form for job seeker", %{conn: conn} do
      {:ok, lv, html} = live(conn, ~p"/users/profile")

      assert html =~ "Fill in your profile to continue"
      assert html =~ "First Name"
      assert html =~ "Last Name"
      assert html =~ "Gender"

      assert has_element?(lv, "select[name='user[medical_role]']")
      assert has_element?(lv, "select[name='user[department]']")
    end

    test "displays medical role and department options for job seeker", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/users/profile")

      assert html =~ "Registered Nurse (AKP/DNII/HF/FH)"
      assert html =~ "Emergency Department"
      assert html =~ "Intensive Care"
      assert html =~ "Operating Room"
    end
  end

  describe "Job seeker profile validation" do
    setup :register_and_log_in_user

    test "validates required fields on form change", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/users/profile")

      lv
      |> form("form", user: %{first_name: ""})
      |> render_change()

      assert render(lv) =~ "can&#39;t be blank"
    end

    test "shows validation errors for missing required job seeker fields", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/users/profile")

      lv
      |> form("form",
        user: %{
          first_name: "John",
          last_name: "Doe"
        }
      )
      |> render_submit()

      html = render(lv)
      assert html =~ "can&#39;t be blank"
    end

    test "validates field lengths", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/users/profile")

      long_string = String.duplicate("a", 256)

      lv
      |> form("form",
        user: %{
          first_name: long_string,
          last_name: long_string,
          city: String.duplicate("a", 101),
          country: String.duplicate("a", 101),
          street: String.duplicate("a", 256),
          zip_code: String.duplicate("a", 21),
          phone: String.duplicate("1", 21)
        }
      )
      |> render_change()

      html = render(lv)
      assert html =~ "should be at most"
    end
  end

  describe "Profile form submission" do
    setup :register_and_log_in_user

    test "successfully submits job seeker profile and redirects to home", %{
      conn: conn,
      user: user
    } do
      {:ok, lv, _html} = live(conn, ~p"/users/profile")

      valid_attrs = %{
        first_name: "John",
        last_name: "Doe",
        gender: "male",
        date_of_birth: "1990-01-01",
        phone: "+41791234567",
        medical_role: "Registered Nurse (AKP/DNII/HF/FH)",
        department: "Emergency Department",
        street: "Main Street 123",
        city: "Zurich",
        zip_code: "8001",
        country: "Switzerland"
      }

      lv
      |> form("form", user: valid_attrs)
      |> render_submit()

      assert_redirect(lv, "/resume")

      updated_user = Accounts.get_user!(user.id)
      assert updated_user.first_name == "John"
      assert updated_user.last_name == "Doe"
      assert updated_user.gender == :male
      assert updated_user.phone == "+41791234567"
      assert updated_user.medical_role == :"Registered Nurse (AKP/DNII/HF/FH)"
      assert updated_user.department == :"Emergency Department"
      assert updated_user.street == "Main Street 123"
      assert updated_user.city == "Zurich"
      assert updated_user.zip_code == "8001"
      assert updated_user.country == "Switzerland"
    end

    test "successfully submits employer profile and redirects to company page", %{conn: conn} do
      employer = user_fixture(%{user_type: :employer})
      conn = log_in_user(conn, employer)

      {:ok, lv, _html} = live(conn, ~p"/users/profile")

      valid_attrs = %{
        first_name: "Jane",
        last_name: "Smith",
        gender: "female",
        date_of_birth: "1985-05-15",
        phone: "+41791234567",
        street: "Business Ave 456",
        city: "Basel",
        zip_code: "4001",
        country: "Switzerland"
      }

      lv
      |> form("form", user: valid_attrs)
      |> render_submit()

      assert_redirect(lv, "/company")

      updated_user = Accounts.get_user!(employer.id)
      assert updated_user.first_name == "Jane"
      assert updated_user.last_name == "Smith"
      assert updated_user.gender == :female
      assert updated_user.phone == "+41791234567"
      assert updated_user.street == "Business Ave 456"
      assert updated_user.city == "Basel"
      assert updated_user.zip_code == "4001"
      assert updated_user.country == "Switzerland"
    end

    test "handles submission with invalid data", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/users/profile")

      invalid_attrs = %{
        first_name: "",
        last_name: "",
        medical_role: "",
        department: "",
        street: "",
        city: "",
        zip_code: "",
        country: ""
      }

      lv
      |> form("form", user: invalid_attrs)
      |> render_submit()

      html = render(lv)
      assert html =~ "can&#39;t be blank"

      refute_redirected(lv)
    end

    test "handles partial form updates", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/users/profile")

      # Fill in enough fields to avoid validation errors
      partial_attrs = %{
        first_name: "John",
        last_name: "Doe",
        medical_role: "Registered Nurse (AKP/DNII/HF/FH)",
        department: "Emergency Department",
        street: "Main Street 123",
        city: "Zurich",
        zip_code: "8001",
        country: "Switzerland"
      }

      lv
      |> form("form", user: partial_attrs)
      |> render_change()

      html = render(lv)
      # Check that form fields are present and form can be interacted with
      assert has_element?(lv, "input[name='user[first_name]']")
      assert has_element?(lv, "input[name='user[last_name]']")
      # Verify the form responds to changes and doesn't show validation errors
      refute html =~ "can&#39;t be blank"
    end
  end
end
