defmodule BemedaPersonalWeb.AdminLive.InvitationNewTest do
  use BemedaPersonalWeb.ConnCase, async: true

  import BemedaPersonal.AccountsFixtures
  import Phoenix.LiveViewTest

  alias BemedaPersonal.Accounts
  alias BemedaPersonal.Companies
  alias BemedaPersonal.TestUtils

  setup do
    admin_user =
      user_fixture(%{
        email: "admin#{:os.system_time(:microsecond)}@example.com",
        user_type: :employer,
        locale: :en
      })

    admin_username = Application.get_env(:bemeda_personal, :admin)[:username]
    admin_password = Application.get_env(:bemeda_personal, :admin)[:password]
    auth_header = "Basic " <> Base.encode64("#{admin_username}:#{admin_password}")

    %{admin: admin_user, auth_header: auth_header}
  end

  defp admin_conn(conn, auth_header) do
    conn
    |> put_session("locale", "en")
    |> put_req_header("authorization", auth_header)
  end

  describe "mount/3" do
    test "requires admin authentication", %{conn: conn} do
      conn = get(conn, ~p"/admin/invitations/new")
      assert conn.status == 401
      assert conn.resp_body == "Unauthorized"
    end

    test "loads invitation form with admin credentials", %{
      conn: conn,
      auth_header: auth_header,
      admin: admin
    } do
      conn =
        conn
        |> log_in_user(admin)
        |> admin_conn(auth_header)

      {:ok, _live, html} = live(conn, ~p"/admin/invitations/new")

      assert html =~ "Benutzer einladen"
      assert html =~ "Benutzerinformationen"
      assert html =~ "Unternehmensinformationen"
    end

    test "initializes empty user form", %{conn: conn, auth_header: auth_header, admin: admin} do
      conn =
        conn
        |> log_in_user(admin)
        |> admin_conn(auth_header)

      {:ok, live, _html} = live(conn, ~p"/admin/invitations/new")

      assert has_element?(live, "form#invitation_form")
      assert has_element?(live, "input[name='user[first_name]']")
      assert has_element?(live, "input[name='user[last_name]']")
      assert has_element?(live, "input[name='user[email]']")
      assert has_element?(live, "select[name='user[locale]']")
    end

    test "initializes empty company form", %{conn: conn, auth_header: auth_header, admin: admin} do
      conn =
        conn
        |> log_in_user(admin)
        |> admin_conn(auth_header)

      {:ok, live, _html} = live(conn, ~p"/admin/invitations/new")

      assert has_element?(live, "input[name='company[name]']")
      assert has_element?(live, "textarea[name='company[description]']")
      assert has_element?(live, "input[name='company[industry]']")
      assert has_element?(live, "input[name='company[size]']")
      assert has_element?(live, "input[name='company[phone_number]']")
      assert has_element?(live, "input[name='company[website_url]']")
      assert has_element?(live, "input[name='company[address]']")
      assert has_element?(live, "input[name='company[city]']")
      assert has_element?(live, "input[name='company[postal_code]']")
      assert has_element?(live, "input[name='company[location]']")
    end

    test "displays back button to admin dashboard", %{
      conn: conn,
      auth_header: auth_header,
      admin: admin
    } do
      conn =
        conn
        |> log_in_user(admin)
        |> admin_conn(auth_header)

      {:ok, live, _html} = live(conn, ~p"/admin/invitations/new")

      assert has_element?(live, "a[href='/admin']")
    end

    test "displays cancel button", %{conn: conn, auth_header: auth_header, admin: admin} do
      conn =
        conn
        |> log_in_user(admin)
        |> admin_conn(auth_header)

      {:ok, live, html} = live(conn, ~p"/admin/invitations/new")

      assert html =~ "Abbrechen"
      assert has_element?(live, "a[href='/admin']")
    end

    test "displays tooltip on invite button", %{
      conn: conn,
      auth_header: auth_header,
      admin: admin
    } do
      conn =
        conn
        |> log_in_user(admin)
        |> admin_conn(auth_header)

      {:ok, _live, html} = live(conn, ~p"/admin/invitations/new")

      assert html =~ "Einladungshinweis"
      assert html =~ "Magic Link"
    end
  end

  describe "handle_event/3 validate" do
    test "validates user data on change", %{conn: conn, auth_header: auth_header, admin: admin} do
      conn =
        conn
        |> log_in_user(admin)
        |> admin_conn(auth_header)

      {:ok, live, _html} = live(conn, ~p"/admin/invitations/new")

      html =
        live
        |> form("#invitation_form", %{
          "user" => %{"email" => "invalid-email"},
          "company" => %{}
        })
        |> render_change()

      assert html =~ "must have the @ sign and no spaces"
    end

    test "validates company data on change", %{
      conn: conn,
      auth_header: auth_header,
      admin: admin
    } do
      conn =
        conn
        |> log_in_user(admin)
        |> admin_conn(auth_header)

      {:ok, live, _html} = live(conn, ~p"/admin/invitations/new")

      html =
        live
        |> form("#invitation_form", %{
          "user" => %{"email" => "test@example.com"},
          "company" => %{"name" => ""}
        })
        |> render_change()

      assert html =~ "can&#39;t be blank" or html =~ "can't be blank"
    end

    test "shows valid state when all data is correct", %{
      conn: conn,
      auth_header: auth_header,
      admin: admin
    } do
      conn =
        conn
        |> log_in_user(admin)
        |> admin_conn(auth_header)

      {:ok, live, _html} = live(conn, ~p"/admin/invitations/new")

      html =
        live
        |> form("#invitation_form", %{
          "user" => %{
            "first_name" => "John",
            "last_name" => "Doe",
            "email" => "john@example.com",
            "locale" => "en"
          },
          "company" => %{"name" => "Test Company"}
        })
        |> render_change()

      refute html =~ "can&#39;t be blank"
      refute html =~ "must have the @ sign"
    end
  end

  describe "handle_event/3 save" do
    test "creates user and company with valid data", %{
      conn: conn,
      auth_header: auth_header,
      admin: admin
    } do
      conn =
        conn
        |> log_in_user(admin)
        |> admin_conn(auth_header)

      {:ok, live, _html} = live(conn, ~p"/admin/invitations/new")

      live
      |> form("#invitation_form", %{
        "user" => %{
          "first_name" => "Jane",
          "last_name" => "Smith",
          "email" => "jane@example.com",
          "locale" => "de"
        },
        "company" => %{
          "name" => "Test Company GmbH",
          "description" => "A test company",
          "industry" => "Technology"
        }
      })
      |> render_submit()

      assert_redirect(live, "/admin")

      user = Accounts.get_user_by_email("jane@example.com")
      assert user
      assert user.first_name == "Jane"
      assert user.last_name == "Smith"
      assert user.user_type == :employer
      assert user.registration_source == :invited
      refute user.hashed_password

      company = Companies.get_company_by_user(user)
      assert company
      assert company.name == "Test Company GmbH"
      assert company.description == "A test company"
      assert company.industry == "Technology"
      assert company.admin_user_id == user.id
    end

    test "sends login instructions email", %{
      conn: conn,
      auth_header: auth_header,
      admin: admin
    } do
      conn =
        conn
        |> log_in_user(admin)
        |> admin_conn(auth_header)

      {:ok, live, _html} = live(conn, ~p"/admin/invitations/new")

      TestUtils.drain_existing_emails()

      live
      |> form("#invitation_form", %{
        "user" => %{
          "first_name" => "Test",
          "last_name" => "User",
          "email" => "testuser@example.com",
          "locale" => "en"
        },
        "company" => %{"name" => "Test Company"}
      })
      |> render_submit()

      assert_received {:email, email}
      assert email.to == [{"Test User", "testuser@example.com"}]
      assert email.subject =~ "Invitation" or email.subject =~ "Einladung"
    end

    test "displays success message", %{conn: conn, auth_header: auth_header, admin: admin} do
      conn =
        conn
        |> log_in_user(admin)
        |> admin_conn(auth_header)

      {:ok, live, _html} = live(conn, ~p"/admin/invitations/new")

      live
      |> form("#invitation_form", %{
        "user" => %{
          "first_name" => "Success",
          "last_name" => "Test",
          "email" => "success@example.com"
        },
        "company" => %{"name" => "Success Company", "location" => "Zurich"}
      })
      |> render_submit()

      # Check that we got a redirect flash event
      assert_redirect(live, "/admin")
    end

    test "shows user errors when user data is invalid", %{
      conn: conn,
      auth_header: auth_header,
      admin: admin
    } do
      conn =
        conn
        |> log_in_user(admin)
        |> admin_conn(auth_header)

      {:ok, live, _html} = live(conn, ~p"/admin/invitations/new")

      html =
        live
        |> form("#invitation_form", %{
          "user" => %{
            "first_name" => "",
            "email" => "invalid"
          },
          "company" => %{"name" => "Test Company"}
        })
        |> render_submit()

      assert html =~ "can&#39;t be blank" or html =~ "can't be blank"
      assert html =~ "must have the @ sign"
    end

    test "shows company errors when company data is invalid", %{
      conn: conn,
      auth_header: auth_header,
      admin: admin
    } do
      conn =
        conn
        |> log_in_user(admin)
        |> admin_conn(auth_header)

      {:ok, live, _html} = live(conn, ~p"/admin/invitations/new")

      html =
        live
        |> form("#invitation_form", %{
          "user" => %{
            "first_name" => "John",
            "last_name" => "Doe",
            "email" => "john@example.com"
          },
          "company" => %{"name" => ""}
        })
        |> render_submit()

      assert html =~ "can&#39;t be blank" or html =~ "can't be blank"
    end

    test "does not create user if company validation fails", %{
      conn: conn,
      auth_header: auth_header,
      admin: admin
    } do
      conn =
        conn
        |> log_in_user(admin)
        |> admin_conn(auth_header)

      {:ok, live, _html} = live(conn, ~p"/admin/invitations/new")

      live
      |> form("#invitation_form", %{
        "user" => %{
          "first_name" => "John",
          "last_name" => "Doe",
          "email" => "rollback@example.com"
        },
        "company" => %{"name" => ""}
      })
      |> render_submit()

      refute Accounts.get_user_by_email("rollback@example.com")
    end

    test "prevents duplicate email registration", %{
      conn: conn,
      auth_header: auth_header,
      admin: admin
    } do
      existing_user = user_fixture(%{email: "existing@example.com"})

      conn =
        conn
        |> log_in_user(admin)
        |> admin_conn(auth_header)

      {:ok, live, _html} = live(conn, ~p"/admin/invitations/new")

      html =
        live
        |> form("#invitation_form", %{
          "user" => %{
            "first_name" => "Duplicate",
            "last_name" => "User",
            "email" => existing_user.email
          },
          "company" => %{"name" => "Duplicate Company"}
        })
        |> render_submit()

      assert html =~ "has already been taken"
    end

    test "defaults user type to employer", %{
      conn: conn,
      auth_header: auth_header,
      admin: admin
    } do
      conn =
        conn
        |> log_in_user(admin)
        |> admin_conn(auth_header)

      {:ok, live, _html} = live(conn, ~p"/admin/invitations/new")

      live
      |> form("#invitation_form", %{
        "user" => %{
          "first_name" => "Employer",
          "last_name" => "Test",
          "email" => "employer@example.com"
        },
        "company" => %{"name" => "Employer Company"}
      })
      |> render_submit()

      user = Accounts.get_user_by_email("employer@example.com")
      assert user.user_type == :employer
    end

    test "defaults registration source to invited", %{
      conn: conn,
      auth_header: auth_header,
      admin: admin
    } do
      conn =
        conn
        |> log_in_user(admin)
        |> admin_conn(auth_header)

      {:ok, live, _html} = live(conn, ~p"/admin/invitations/new")

      live
      |> form("#invitation_form", %{
        "user" => %{
          "first_name" => "Invited",
          "last_name" => "Test",
          "email" => "invited@example.com"
        },
        "company" => %{"name" => "Invited Company"}
      })
      |> render_submit()

      user = Accounts.get_user_by_email("invited@example.com")
      assert user.registration_source == :invited
    end

    test "creates company with all provided fields", %{
      conn: conn,
      auth_header: auth_header,
      admin: admin
    } do
      conn =
        conn
        |> log_in_user(admin)
        |> admin_conn(auth_header)

      {:ok, live, _html} = live(conn, ~p"/admin/invitations/new")

      unique_email = "fulldata#{:os.system_time(:microsecond)}@example.com"

      TestUtils.drain_existing_emails()

      live
      |> form("#invitation_form", %{
        "user" => %{
          "first_name" => "Full",
          "last_name" => "Data",
          "email" => unique_email
        },
        "company" => %{
          "name" => "Full Data Company",
          "description" => "Complete company info",
          "industry" => "Tech",
          "size" => "50-100",
          "phone_number" => "+41791234567",
          "website_url" => "https://example.com",
          "address" => "Main Street 1",
          "city" => "Zurich",
          "postal_code" => "8000",
          "location" => "Zurich"
        }
      })
      |> render_submit()

      # Wait a bit for async operations
      Process.sleep(100)

      user = Accounts.get_user_by_email(unique_email)
      company = Companies.get_company_by_user(user)

      assert company.name == "Full Data Company"
      assert company.description == "Complete company info"
      assert company.phone_number == "+41791234567"
      assert company.website_url == "https://example.com"
      assert company.address == "Main Street 1"
      assert company.city == "Zurich"
      assert company.postal_code == "8000"
      assert company.location == :Zurich
    end
  end

  describe "permissions" do
    test "non-admin user cannot access invitation form", %{conn: conn} do
      regular_user = user_fixture(%{user_type: :employer})

      result =
        conn
        |> log_in_user(regular_user)
        |> get(~p"/admin/invitations/new")

      assert result.status == 401
    end

    test "job seeker cannot access invitation form", %{conn: conn} do
      job_seeker = user_fixture(%{user_type: :job_seeker})

      result =
        conn
        |> log_in_user(job_seeker)
        |> get(~p"/admin/invitations/new")

      assert result.status == 401
    end
  end

  describe "navigation" do
    test "cancel button redirects to admin dashboard", %{
      conn: conn,
      auth_header: auth_header,
      admin: admin
    } do
      conn =
        conn
        |> log_in_user(admin)
        |> admin_conn(auth_header)

      {:ok, live, html} = live(conn, ~p"/admin/invitations/new")

      # Find the cancel button (not the back arrow)
      assert html =~ "Abbrechen"

      # Click the cancel button patch link
      {:ok, _live, _html} =
        live
        |> element("a", "Abbrechen")
        |> render_click()
        |> follow_redirect(conn, "/admin")
    end

    test "back button redirects to admin dashboard", %{
      conn: conn,
      auth_header: auth_header,
      admin: admin
    } do
      conn =
        conn
        |> log_in_user(admin)
        |> admin_conn(auth_header)

      {:ok, live, _html} = live(conn, ~p"/admin/invitations/new")

      assert has_element?(live, "a[href='/admin']")
    end
  end

  describe "form fields" do
    test "displays all required user fields", %{
      conn: conn,
      auth_header: auth_header,
      admin: admin
    } do
      conn =
        conn
        |> log_in_user(admin)
        |> admin_conn(auth_header)

      {:ok, _live, html} = live(conn, ~p"/admin/invitations/new")

      assert html =~ "Vorname"
      assert html =~ "Nachname"
      assert html =~ "E-Mail"
      assert html =~ "Sprache"
    end

    test "displays all company fields", %{conn: conn, auth_header: auth_header, admin: admin} do
      conn =
        conn
        |> log_in_user(admin)
        |> admin_conn(auth_header)

      {:ok, _live, html} = live(conn, ~p"/admin/invitations/new")

      assert html =~ "Unternehmensname"
      assert html =~ "Beschreibung"
      assert html =~ "Branche"
      assert html =~ "Unternehmensgröße"
      assert html =~ "Telefonnummer"
      assert html =~ "Website-URL"
      assert html =~ "Adresse"
      assert html =~ "Stadt"
      assert html =~ "Postleitzahl"
      assert html =~ "Standort"
    end

    test "language selector has all options", %{
      conn: conn,
      auth_header: auth_header,
      admin: admin
    } do
      conn =
        conn
        |> log_in_user(admin)
        |> admin_conn(auth_header)

      {:ok, _live, html} = live(conn, ~p"/admin/invitations/new")

      assert html =~ "Deutsch"
      assert html =~ "English"
      assert html =~ "Français"
      assert html =~ "Italiano"
    end
  end
end
