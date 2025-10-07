defmodule BemedaPersonalWeb.UserSettingsLive.InfoTest do
  use BemedaPersonalWeb.ConnCase, async: false

  import BemedaPersonal.AccountsFixtures
  import BemedaPersonal.CompaniesFixtures
  import BemedaPersonal.JobApplicationsFixtures
  import BemedaPersonal.JobPostingsFixtures
  import BemedaPersonal.RatingsFixtures
  import Phoenix.LiveViewTest

  alias BemedaPersonal.Media.MediaAsset
  alias BemedaPersonal.Ratings

  describe "user ratings" do
    setup %{conn: conn} do
      user = user_fixture(%{confirmed: true})
      company_admin = employer_user_fixture(%{confirmed: true})
      company1 = company_fixture(company_admin)
      company2 = company_fixture(employer_user_fixture(%{confirmed: true}))
      job_posting1 = job_posting_fixture(company1)
      job_posting2 = job_posting_fixture(company2)
      job_application1 = job_application_fixture(user, job_posting1)
      job_application2 = job_application_fixture(user, job_posting2)

      %{
        company1: company1,
        company2: company2,
        conn: log_in_user(conn, user),
        job_application1: job_application1,
        job_application2: job_application2,
        job_posting1: job_posting1,
        job_posting2: job_posting2,
        user: user
      }
    end

    test "displays component with no ratings", %{conn: conn} do
      {:ok, view, html} = live(conn, ~p"/users/settings/info")

      assert html =~ "Your Rating"
      assert html =~ "How companies have rated your applications"
      assert html =~ "hero-star"
      assert html =~ "(0)"
      assert html =~ "No ratings yet"
      refute html =~ "fill-current"

      refute has_element?(view, "button", "Rate")
      refute has_element?(view, "button", "Update Rating")
    end

    test "displays correct rating with single rating", %{
      company1: company,
      conn: conn,
      user: user
    } do
      rating_fixture(%{
        comment: "Excellent candidate!",
        ratee_id: user.id,
        ratee_type: "User",
        rater_id: company.id,
        rater_type: "Company",
        score: 5
      })

      {:ok, _view, html} = live(conn, ~p"/users/settings/info")

      assert html =~ "Your Rating"
      assert html =~ "5.0"
      assert html =~ "(1)"
      assert html =~ "fill-current"
    end

    test "displays average of multiple ratings correctly", %{
      company1: company1,
      company2: company2,
      conn: conn,
      user: user
    } do
      rating_fixture(%{
        comment: "Excellent!",
        ratee_id: user.id,
        ratee_type: "User",
        rater_id: company1.id,
        rater_type: "Company",
        score: 5
      })

      rating_fixture(%{
        comment: "Average",
        ratee_id: user.id,
        ratee_type: "User",
        rater_id: company2.id,
        rater_type: "Company",
        score: 3
      })

      {:ok, _view, html} = live(conn, ~p"/users/settings/info")

      assert html =~ "Your Rating"
      assert html =~ "4.0"
      assert html =~ "(2)"
      assert html =~ "fill-current"
    end

    test "updates display when rating changes", %{
      company1: company,
      conn: conn,
      user: user
    } do
      {:ok, view, html} = live(conn, ~p"/users/settings/info")

      assert html =~ "(0)"
      assert html =~ "No ratings yet"
      refute html =~ "fill-current"

      Ratings.rate_user(company, user, %{comment: "Very good candidate", score: 4})

      # Flaky test, sometimes the rating is not updated in time
      Process.sleep(100)

      updated_html = render(view)
      assert updated_html =~ "4.0"
      assert updated_html =~ "(1)"
      assert updated_html =~ "fill-current"
    end
  end

  describe "Progressive validation behavior" do
    setup %{conn: conn} do
      user = user_fixture(%{confirmed: true, locale: "en"})

      conn =
        conn
        |> Phoenix.ConnTest.init_test_session(%{})
        |> put_session(:locale, "en")
        |> log_in_user(user)

      %{conn: conn, user: user}
    end

    test "email form shows progressive then complete validation", %{conn: conn} do
      {:ok, lv, html} = live(conn, ~p"/users/settings/info")

      # First check if page loads correctly
      assert html =~ "Account Information"

      # Click edit button to show forms
      lv
      |> element("button[phx-click*=edit_account]")
      |> render_click()

      # Get the full rendered page after clicking edit
      edit_html = render(lv)
      assert edit_html =~ "email_form"

      # During editing - only show error for touched email field
      lv
      |> form("#email_form", %{
        "user" => %{"email" => "invalid"}
        # Note: not providing current_password yet
      })
      |> render_change()

      # Get the full page after change
      result = render(lv)

      assert result =~ "must have the @ sign"
      # current_password error should not show yet
      refute result =~ "is not valid"

      # After submission - show ALL errors
      lv
      |> form("#email_form", %{
        "current_password" => "",
        "user" => %{"email" => "invalid"}
      })
      |> render_submit()

      # Get the full page after submit
      submit_result = render(lv)

      # email error
      assert submit_result =~ "must have the @ sign"
      # current_password error now visible
      assert submit_result =~ "is not valid"
    end

    test "personal info form shows progressive then complete validation", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/users/settings/info")

      # Click edit button to show forms
      lv
      |> element("button[phx-click*=edit_account]")
      |> render_click()

      assert lv
             |> element("#personal_info_form")
             |> render_change(%{
               "user" => %{"first_name" => ""}
               # Note: not touching other required fields yet
             }) =~ "can&#39;t be blank"

      assert lv
             |> element("#personal_info_form")
             |> render_submit(%{
               "user" => %{
                 # invalid
                 "first_name" => "",
                 # invalid
                 "last_name" => "",
                 # invalid
                 "street" => "",
                 # valid
                 "zip_code" => "12345",
                 # invalid
                 "city" => "",
                 # invalid
                 "country" => ""
               }
             }) =~ "can&#39;t be blank"
    end

    test "password form shows progressive then complete validation", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/users/settings/password")

      # During editing - only show error for touched password field
      result =
        lv
        |> element("#password_form")
        |> render_change(%{
          "user" => %{"password" => "short"}
          # Note: not providing current_password or confirmation yet
        })

      # password error
      assert result =~ "should be at least 12 character"
      # current_password error should not show yet
      refute result =~ "can&#39;t be blank"

      # After submission - show ALL errors
      submit_result =
        lv
        |> element("#password_form")
        |> render_submit(%{
          "current_password" => "",
          "user" => %{
            "password" => "short",
            "password_confirmation" => "different"
          }
        })

      # password error
      assert submit_result =~ "should be at least 12 character"
      # confirmation error
      assert submit_result =~ "does not match password"
      # current_password error now visible
      assert submit_result =~ "is not valid"
    end
  end

  describe "Employer user with company" do
    setup %{conn: conn} do
      employer = employer_user_fixture(%{confirmed: true})

      company =
        company_fixture(employer, %{
          name: "Test Company",
          description: "A great company",
          organization_type: "Hospital",
          size: "50-100",
          location: "Zurich, Switzerland",
          phone_number: "+41441234567",
          website_url: "https://example.com"
        })

      %{conn: log_in_user(conn, employer), employer: employer, company: company}
    end

    test "shows company information section for employers", %{conn: conn, company: company} do
      {:ok, _view, html} = live(conn, ~p"/users/settings/info")

      # Company section should be visible
      assert html =~ "Company Information"
      assert html =~ company.name
      assert html =~ company.description
      assert html =~ company.organization_type
      assert html =~ company.size
      assert html =~ company.location
      assert html =~ company.phone_number
      assert html =~ company.website_url

      # Edit button should be present
      assert html =~ "edit_company"
    end

    test "can edit company information inline", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/users/settings/info")

      # Click edit company button using render_hook
      render_hook(view, "edit_company", %{})

      # Form should be shown
      assert has_element?(view, "#company_form_inline")

      # Update company information
      updated_html =
        view
        |> form("#company_form_inline", %{
          "company" => %{
            "name" => "Updated Company",
            "description" => "Updated description",
            "organization_type" => "Clinic",
            "size" => "100-500",
            "location" => "Basel, Switzerland",
            "phone_number" => "+41619998888",
            "website_url" => "https://updated.com"
          }
        })
        |> render_submit()

      # Should redirect back to view mode
      assert updated_html =~ "Company updated successfully"
      assert updated_html =~ "Updated Company"
      assert updated_html =~ "Updated description"
      refute has_element?(view, "#company_form_inline")
    end

    test "validates company form", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/users/settings/info")

      # Click edit company button using render_hook
      render_hook(view, "edit_company", %{})

      # Submit with empty name
      result =
        view
        |> form("#company_form_inline", %{
          "company" => %{
            "name" => "",
            "website_url" => "not-a-url"
          }
        })
        |> render_change()

      assert result =~ "can&#39;t be blank"
      assert result =~ "must start with http:// or https://"
    end

    test "can cancel company edit", %{conn: conn, company: company} do
      {:ok, view, _html} = live(conn, ~p"/users/settings/info")

      # Click edit company button using render_hook
      render_hook(view, "edit_company", %{})

      # Click cancel using render_hook
      render_hook(view, "cancel_edit", %{})

      # Should be back in view mode
      updated_html = render(view)
      refute has_element?(view, "#company_form_inline")
      assert updated_html =~ company.name
    end
  end

  describe "Company Media Asset Handling (Bug Fix)" do
    setup %{conn: conn} do
      employer = employer_user_fixture(%{confirmed: true})
      company = company_fixture(employer, %{name: "Media Test Company"})

      %{conn: log_in_user(conn, employer), employer: employer, company: company}
    end

    test "handles company with nil media_asset without crashing", %{conn: conn, company: company} do
      # Explicitly set media_asset_id to nil
      {:ok, updated_company} =
        BemedaPersonal.Companies.update_company(company, %{media_asset_id: nil})

      # Should load successfully without KeyError
      {:ok, _view, html} = live(conn, ~p"/users/settings/info")

      # Should display company information section
      assert html =~ "Company Information"
      assert html =~ updated_company.name

      # Should show company info without crashing on media asset access
      refute html =~ "KeyError"
      refute html =~ "500 Internal Server Error"

      # The template has conditional rendering: <%= if @company.media_asset do %>
      # So when media_asset is nil, the company logo img tag should not be present
      # We check for the specific company logo image with its distinctive classes
      refute html =~ "object-cover rounded-full"
      refute html =~ ~s(alt="#{updated_company.name}")
    end

    test "displays company logo when media_asset exists", %{conn: conn, company: company} do
      # Create media asset for company
      {:ok, _media_asset} =
        BemedaPersonal.Media.create_media_asset(company, %{
          file_name: "company_logo.png",
          status: :uploaded,
          type: "image/png",
          upload_id: Ecto.UUID.generate()
        })

      # Reload company to get media_asset association
      company = BemedaPersonal.Repo.preload(company, :media_asset, force: true)
      assert company.media_asset != nil

      # Update the company to ensure it has the media_asset
      {:ok, updated_company} =
        BemedaPersonal.Companies.update_company(company, %{
          media_asset_id: company.media_asset.id
        })

      # Should load successfully and display company logo
      {:ok, _view, html} = live(conn, ~p"/users/settings/info")

      assert html =~ "Company Information"
      assert html =~ updated_company.name

      # Should contain img tag when media_asset exists
      assert html =~ ~s(<img)
      assert html =~ "object-cover"
      assert html =~ "rounded-full"

      # Template uses Media.get_media_asset_url(@company.media_asset)
      # which should generate a proper URL
      refute html =~ "KeyError"
    end

    test "handles malformed media_asset gracefully", %{conn: conn, company: company} do
      # Create media asset with valid upload_id first
      {:ok, media_asset} =
        BemedaPersonal.Media.create_media_asset(company, %{
          file_name: "broken_logo.png",
          status: :uploaded,
          type: "image/png",
          upload_id: Ecto.UUID.generate()
        })

      # Manually set upload_id to nil to simulate edge case
      media_asset
      |> MediaAsset.changeset(%{upload_id: nil})
      |> BemedaPersonal.Repo.update!()

      # Update company to have the malformed media_asset
      {:ok, _updated_company} =
        BemedaPersonal.Companies.update_company(company, %{
          media_asset_id: media_asset.id
        })

      # Should handle nil upload_id gracefully (Media.get_media_asset_url returns nil)
      {:ok, _view, html} = live(conn, ~p"/users/settings/info")

      assert html =~ "Company Information"
      assert html =~ company.name

      # Should still not crash even with malformed media_asset
      refute html =~ "KeyError"
      refute html =~ "500 Internal Server Error"

      # The component should still render the img tag with src pointing to the helper function
      # Media.get_media_asset_url will return nil for nil upload_id, but template still renders
      assert html =~ ~s(<img)
    end

    test "edit mode also handles nil media_asset without crashing", %{
      conn: conn,
      company: company
    } do
      # Set media_asset_id to nil
      {:ok, _updated_company} =
        BemedaPersonal.Companies.update_company(company, %{media_asset_id: nil})

      {:ok, view, _html} = live(conn, ~p"/users/settings/info")

      # Click edit company button to enter edit mode
      render_hook(view, "edit_company", %{})

      # Should load edit mode without crashing
      edit_html = render(view)

      assert edit_html =~ "Company Information"
      assert edit_html =~ "company_form_inline"

      # Should show edit mode company logo area without crashing
      refute edit_html =~ "KeyError"
      refute edit_html =~ "500 Internal Server Error"

      # In edit mode, the template also uses: <%= if @company.media_asset do %>
      # So company logo img should not be present when media_asset is nil
      # We check for the specific company logo image with its distinctive classes
      refute edit_html =~ "object-cover rounded-full"
    end
  end

  describe "Job seeker user without company" do
    setup %{conn: conn} do
      user = user_fixture(%{confirmed: true, user_type: :job_seeker})
      %{conn: log_in_user(conn, user), user: user}
    end

    test "does not show company section for job seekers", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/users/settings/info")

      # Company section should not be visible
      refute html =~ "Company Information"
      refute html =~ "Organization Name"
      refute html =~ "View public profile"
    end
  end
end
