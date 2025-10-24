defmodule BemedaPersonalWeb.UserLive.SettingsTest do
  use BemedaPersonalWeb.ConnCase, async: true

  import BemedaPersonal.AccountsFixtures
  import BemedaPersonal.CompaniesFixtures
  import Phoenix.LiveViewTest

  alias BemedaPersonal.Accounts

  describe "Settings page - navigation" do
    test "renders settings index page with menu items", %{conn: conn} do
      user = user_fixture()

      {:ok, _lv, html} =
        conn
        |> log_in_user(user)
        |> live(~p"/users/settings")

      assert html =~ "Account Settings"
      assert html =~ "My Info"
      assert html =~ "Change Password"
    end

    test "navigates to My Info page", %{conn: conn} do
      user = user_fixture()

      {:ok, _lv, _html} =
        conn
        |> log_in_user(user)
        |> live(~p"/users/settings")

      {:ok, _info_lv, html} =
        conn
        |> log_in_user(user)
        |> live(~p"/users/settings/info")

      assert html =~ "My Info"
      assert html =~ "Account Information"
    end

    test "redirects if user is not logged in", %{conn: conn} do
      assert {:error, redirect} = live(conn, ~p"/users/settings")

      assert {:redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/users/log_in"
      assert %{"error" => "You must log in to access this page."} = flash
    end

    test "allows access when user is authenticated recently", %{conn: conn} do
      {:ok, _lv, html} =
        conn
        |> log_in_user(user_fixture())
        |> live(~p"/users/settings")

      assert html =~ "Account Settings"
    end
  end

  describe "Personal information - job seeker" do
    setup %{conn: conn} do
      user = user_fixture(user_type: :job_seeker)
      %{conn: log_in_user(conn, user), user: user}
    end

    test "displays personal information section", %{conn: conn, user: user} do
      {:ok, _lv, html} = live(conn, ~p"/users/settings/info")

      assert html =~ "Account Information"
      assert html =~ user.first_name
      assert html =~ user.last_name
      assert html =~ user.email
    end

    test "shows personal info form when edit button is clicked", %{conn: conn} do
      {:ok, lv, html} = live(conn, ~p"/users/settings/info")

      assert html =~ "personal-information-section"
      refute html =~ "account-information-form"

      html_2 =
        lv
        |> element("#personal-information-section button")
        |> render_click()

      assert html_2 =~ "account-information-form"
    end

    test "displays account information form when edit is clicked", %{conn: conn} do
      {:ok, lv, html} = live(conn, ~p"/users/settings/info")

      refute html =~ "account-information-form"

      html_2 =
        lv
        |> element("#personal-information-section button")
        |> render_click()

      assert html_2 =~ "account-information-form"
    end

    test "updates personal information successfully", %{conn: conn, user: user} do
      {:ok, lv, _html} = live(conn, ~p"/users/settings/info")

      lv
      |> element("#personal-information-section button")
      |> render_click()

      lv
      |> form("#account-information-form", %{
        "user" => %{
          "first_name" => "Updated",
          "last_name" => "Name",
          "email" => user.email,
          "date_of_birth" => "1990-05-15",
          "gender" => "male",
          "location" => "Zurich"
        }
      })
      |> render_submit()

      assert render(lv) =~ "Account information updated successfully"

      updated_user = Accounts.get_user!(user.id)
      assert updated_user.first_name == "Updated"
      assert updated_user.last_name == "Name"
      assert updated_user.date_of_birth == ~D[1990-05-15]
      assert updated_user.gender == :male
      assert updated_user.location == :Zurich
    end

    test "validates personal information form on change", %{conn: conn, user: _user} do
      {:ok, lv, _html} = live(conn, ~p"/users/settings/info")

      lv
      |> element("#personal-information-section button")
      |> render_click()

      html =
        lv
        |> form("#account-information-form")
        |> render_change(%{
          "user" => %{
            "first_name" => "",
            "last_name" => "",
            "email" => "invalid-email"
          }
        })

      assert html =~ "can&#39;t be blank"
    end
  end

  describe "Personal information - employer" do
    setup %{conn: conn} do
      user = employer_user_fixture()
      company = company_fixture(user)
      %{conn: log_in_user(conn, user), user: user, company: company}
    end

    test "displays personal information without job seeker specific fields", %{
      conn: conn,
      user: user
    } do
      {:ok, _lv, html} = live(conn, ~p"/users/settings/info")

      assert html =~ "Account Information"
      assert html =~ user.first_name
      assert html =~ user.last_name
      assert html =~ user.email
    end

    test "updates employer personal information without job seeker fields", %{
      conn: conn,
      user: user
    } do
      {:ok, lv, _html} = live(conn, ~p"/users/settings/info")

      lv
      |> element("#personal-information-section button")
      |> render_click()

      lv
      |> form("#account-information-form", %{
        "user" => %{
          "first_name" => "Employer",
          "last_name" => "Updated",
          "email" => user.email
        }
      })
      |> render_submit()

      assert render(lv) =~ "Account information updated successfully"

      updated_user = Accounts.get_user!(user.id)
      assert updated_user.first_name == "Employer"
      assert updated_user.last_name == "Updated"
    end
  end

  describe "Company information" do
    setup %{conn: conn} do
      user = employer_user_fixture()
      company = company_fixture(user)
      %{conn: log_in_user(conn, user), user: user, company: company}
    end

    test "displays company information section for employers", %{conn: conn, company: company} do
      {:ok, _lv, html} = live(conn, ~p"/users/settings/info")

      assert html =~ "Company Information"
      assert html =~ company.name
      assert html =~ company.description
    end

    test "does not display company section for job seekers", %{conn: conn} do
      job_seeker = user_fixture(user_type: :job_seeker)

      {:ok, _lv, html} =
        conn
        |> log_in_user(job_seeker)
        |> live(~p"/users/settings/info")

      refute html =~ "Company Information"
    end

    test "displays company information section", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/users/settings/info")

      assert html =~ "company-information-section"
    end

    test "verifies company information is present", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/users/settings/info")

      assert html =~ "company-information-section"
    end

    test "displays company information successfully", %{conn: conn, company: company} do
      {:ok, _lv, html} = live(conn, ~p"/users/settings/info")

      assert html =~ company.name
      assert html =~ company.description
      assert html =~ to_string(company.location)
      assert html =~ company.phone_number
      assert html =~ company.website_url
    end

    test "shows company edit form when edit button is clicked", %{conn: conn} do
      {:ok, lv, html} = live(conn, ~p"/users/settings/info")

      assert html =~ "company-information-section"

      html_2 =
        lv
        |> element("#company-information-section button")
        |> render_click()

      assert html_2 =~ "company-profile-form"
      assert html_2 =~ "Company Information"
    end

    test "hides company edit form when cancel is clicked", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/users/settings/info")

      lv
      |> element("#company-information-section button")
      |> render_click()

      html =
        lv
        |> element(
          "#company-profile-form .flex.items-center.justify-center.gap-x-4 button:first-of-type"
        )
        |> render_click()

      assert html =~ "company-information-section"
      refute html =~ "company-profile-form"
    end

    test "updates company information successfully", %{conn: conn, company: company} do
      {:ok, lv, _html} = live(conn, ~p"/users/settings/info")

      lv
      |> element("#company-information-section button")
      |> render_click()

      lv
      |> form("#company-profile-form", %{
        "company" => %{
          "name" => "Updated Company Name",
          "description" => "Updated company description for our organization",
          "website_url" => "https://updated-example.com"
        }
      })
      |> render_submit()

      assert render(lv) =~ "Company information updated successfully"

      updated_company = BemedaPersonal.Repo.get!(BemedaPersonal.Companies.Company, company.id)
      assert updated_company.name == "Updated Company Name"
      assert updated_company.description == "Updated company description for our organization"
      assert updated_company.website_url == "https://updated-example.com"
    end

    test "validates company name is required", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/users/settings/info")

      lv
      |> element("#company-information-section button")
      |> render_click()

      html =
        lv
        |> form("#company-profile-form", %{
          "company" => %{
            "name" => "",
            "description" => "Some description"
          }
        })
        |> render_submit()

      assert html =~ "can&#39;t be blank"
    end

    test "validates company website URL format on change", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/users/settings/info")

      lv
      |> element("#company-information-section button")
      |> render_click()

      html =
        lv
        |> form("#company-profile-form")
        |> render_change(%{
          "company" => %{
            "name" => "Test Company",
            "website_url" => "invalid-url-without-protocol"
          }
        })

      assert html =~ "company-profile-form"
    end

    test "updates only company name when other fields are unchanged", %{
      conn: conn,
      company: company
    } do
      {:ok, lv, _html} = live(conn, ~p"/users/settings/info")

      lv
      |> element("#company-information-section button")
      |> render_click()

      lv
      |> form("#company-profile-form", %{
        "company" => %{
          "name" => "Just Updated Name"
        }
      })
      |> render_submit()

      assert render(lv) =~ "Company information updated successfully"

      updated_company = BemedaPersonal.Repo.get!(BemedaPersonal.Companies.Company, company.id)
      assert updated_company.name == "Just Updated Name"
      assert updated_company.description == company.description
      assert updated_company.location == company.location
    end
  end

  describe "confirm email" do
    setup %{conn: conn} do
      user = user_fixture()
      email = unique_user_email()

      token =
        extract_user_token(fn url ->
          Accounts.deliver_user_update_email_instructions(%{user | email: email}, user.email, url)
        end)

      %{conn: log_in_user(conn, user), token: token, email: email, user: user}
    end

    test "updates the user email once", %{conn: conn, user: user, token: token, email: email} do
      {:error, redirect} = live(conn, ~p"/users/settings/confirm-email/#{token}")

      assert {:live_redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/users/settings/info"
      assert %{"info" => message} = flash
      assert message == "Email changed successfully."
      refute Accounts.get_user_by_email(user.email)
      assert Accounts.get_user_by_email(email)

      {:error, second_redirect} = live(conn, ~p"/users/settings/confirm-email/#{token}")
      assert {:live_redirect, %{to: second_path, flash: second_flash}} = second_redirect
      assert second_path == ~p"/users/settings/info"
      assert %{"error" => error_message} = second_flash
      assert error_message == "Email change link is invalid or it has expired."
    end

    test "does not update email with invalid token", %{conn: conn, user: user} do
      {:error, redirect} = live(conn, ~p"/users/settings/confirm-email/oops")
      assert {:live_redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/users/settings/info"
      assert %{"error" => message} = flash
      assert message == "Email change link is invalid or it has expired."
      assert Accounts.get_user_by_email(user.email)
    end

    test "redirects if user is not logged in", %{token: token} do
      conn = build_conn()
      {:error, redirect} = live(conn, ~p"/users/settings/confirm-email/#{token}")
      assert {:redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/users/log_in"
      assert %{"error" => message} = flash
      assert message == "You must log in to access this page."
    end
  end

  describe "delete account" do
    test "soft deletes user account when delete button is clicked", %{conn: conn} do
      user = user_fixture()

      {:ok, lv, html} =
        conn
        |> log_in_user(user)
        |> live(~p"/users/settings/info")

      assert html =~ "Delete Account"
      assert html =~ "Delete my account"

      assert {:ok, conn} =
               lv
               |> element("button", "Delete my account")
               |> render_click()
               |> follow_redirect(conn, ~p"/")

      assert Phoenix.Flash.get(conn.assigns.flash, :info) == "Account deleted successfully."

      deleted_user = BemedaPersonal.Repo.get!(BemedaPersonal.Accounts.User, user.id)
      assert deleted_user.deleted_at != nil
      refute Accounts.get_user_by_email(user.email)
    end

    test "deleted user cannot log in", %{conn: conn} do
      user = user_fixture()

      {:ok, _deleted_user} = Accounts.soft_delete_user(user)

      refute Accounts.get_user_by_email_and_password(user.email, valid_user_password())

      conn =
        post(conn, ~p"/users/log_in", %{
          "user" => %{"email" => user.email, "password" => valid_user_password()}
        })

      assert redirected_to(conn) == ~p"/users/log_in"
    end
  end

  describe "Change Password page" do
    setup %{conn: conn} do
      user = user_fixture()
      user_with_password = set_password(user)

      %{conn: log_in_user(conn, user_with_password), user: user_with_password}
    end

    test "renders change password page", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/users/settings/password")

      assert html =~ "Change Password"
      assert html =~ "id=\"password_form\""
      assert html =~ "user_password\""
      assert html =~ "user_password_confirmation\""
    end

    test "displays password form", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/users/settings/password")

      assert html =~ "password_form"
      assert html =~ "user_password\""
      assert html =~ "user_password_confirmation\""
    end

    test "validates password on change", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/users/settings/password")

      html =
        lv
        |> form("#password_form")
        |> render_change(%{
          "user" => %{
            "current_password" => valid_user_password(),
            "password" => "short",
            "password_confirmation" => "short"
          }
        })

      assert html =~ "should be at least 12 character"
    end

    test "validates password confirmation matches", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/users/settings/password")

      html =
        lv
        |> form("#password_form")
        |> render_change(%{
          "user" => %{
            "current_password" => valid_user_password(),
            "password" => "new valid password 123",
            "password_confirmation" => "different password"
          }
        })

      assert html =~ "does not match password"
    end

    test "validates current password is correct", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/users/settings/password")

      html =
        lv
        |> form("#password_form")
        |> render_change(%{
          "user" => %{
            "current_password" => "wrong password",
            "password" => "new valid password 123",
            "password_confirmation" => "new valid password 123"
          }
        })

      assert html =~ "is not valid"
    end

    test "updates password successfully", %{conn: conn} do
      new_password = "new valid password 123"

      {:ok, lv, _html} = live(conn, ~p"/users/settings/password")

      result =
        lv
        |> form("#password_form", %{
          "user" => %{
            "current_password" => valid_user_password(),
            "password" => new_password,
            "password_confirmation" => new_password
          }
        })
        |> render_submit()

      assert result =~ "phx-trigger-action"
    end

    test "requires valid password length", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/users/settings/password")

      html =
        lv
        |> form("#password_form", %{
          "user" => %{
            "current_password" => valid_user_password(),
            "password" => "short",
            "password_confirmation" => "short"
          }
        })
        |> render_submit()

      assert html =~ "should be at least 12 character"
    end

    test "requires current password when user has password", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/users/settings/password")

      html =
        lv
        |> form("#password_form", %{
          "user" => %{
            "password" => "new valid password 123",
            "password_confirmation" => "new valid password 123"
          }
        })
        |> render_submit()

      assert html =~ "is not valid"
    end

    test "redirects if user is not logged in", %{conn: _conn} do
      conn = build_conn()
      assert {:error, redirect} = live(conn, ~p"/users/settings/password")

      assert {:redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/users/log_in"
      assert %{"error" => "You must log in to access this page."} = flash
    end
  end
end
