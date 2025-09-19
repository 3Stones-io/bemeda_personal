defmodule BemedaPersonal.RatingsTest do
  use BemedaPersonal.DataCase, async: true

  import BemedaPersonal.AccountsFixtures
  import BemedaPersonal.CompaniesFixtures
  import BemedaPersonal.JobApplicationsFixtures
  import BemedaPersonal.JobPostingsFixtures
  import BemedaPersonal.RatingsFixtures

  alias BemedaPersonal.Ratings
  alias BemedaPersonalWeb.Endpoint

  setup do
    user = user_fixture(confirmed: true)
    company_admin = employer_user_fixture(confirmed: true)
    company = company_fixture(company_admin)

    rating =
      rating_fixture(
        ratee_id: user.id,
        ratee_type: "User",
        rater_id: company.id,
        rater_type: "Company"
      )

    %{rating: rating, user: user, company: company, company_admin: company_admin}
  end

  describe "list_ratings_by_ratee_id/2" do
    test "returns ratings for a specific ratee", %{rating: rating, user: user} do
      assert [^rating] = Ratings.list_ratings_by_ratee_id("User", user.id)
    end

    test "returns empty list when no ratings exist for ratee" do
      assert Ratings.list_ratings_by_ratee_id("User", Ecto.UUID.generate()) == []
    end
  end

  describe "get_rating_by_rater_and_ratee/4" do
    test "returns the rating when it exists", %{rating: rating, company: company, user: user} do
      assert Ratings.get_rating_by_rater_and_ratee("Company", company.id, "User", user.id) ==
               rating
    end

    test "returns nil when rating doesn't exist" do
      assert Ratings.get_rating_by_rater_and_ratee(
               "User",
               Ecto.UUID.generate(),
               "Company",
               Ecto.UUID.generate()
             ) == nil
    end
  end

  describe "rate_company/3" do
    setup do
      user = user_fixture(confirmed: true)
      company_admin = employer_user_fixture(confirmed: true)
      company = company_fixture(company_admin)
      job_posting = job_posting_fixture(company)
      job_application = job_application_fixture(user, job_posting)

      %{
        company_admin: company_admin,
        company: company,
        job_application: job_application,
        job_posting: job_posting,
        user: user
      }
    end

    test "with valid data creates a rating", %{user: user, company: company} do
      valid_attrs = %{
        score: 4,
        comment: "some comment"
      }

      assert {:ok, %Ratings.Rating{} = rating} = Ratings.rate_company(user, company, valid_attrs)
      assert rating.comment == "some comment"
      assert rating.rater_type == "User"
      assert rating.rater_id == user.id
      assert rating.ratee_type == "Company"
      assert rating.ratee_id == company.id
      assert rating.score == 4
    end

    test "with invalid data returns error changeset", %{user: user, company: company} do
      invalid_attrs = %{score: nil, comment: nil}
      assert {:error, %Ecto.Changeset{}} = Ratings.rate_company(user, company, invalid_attrs)
    end

    test "broadcasts a message when rating is created", %{user: user, company: company} do
      Endpoint.subscribe("rating:Company:#{company.id}")

      valid_attrs = %{
        score: 5,
        comment: "broadcast test comment"
      }

      assert {:ok, %Ratings.Rating{} = rating} = Ratings.rate_company(user, company, valid_attrs)

      assert_receive %Phoenix.Socket.Broadcast{
        event: "rating_updated",
        payload: broadcasted_rating
      }

      assert broadcasted_rating.id == rating.id
      assert broadcasted_rating.comment == "broadcast test comment"
      assert broadcasted_rating.score == 5
    end

    test "user can update an existing company rating", %{user: user, company: company} do
      initial_attrs = %{score: 3, comment: "Good company"}
      {:ok, _rating} = Ratings.rate_company(user, company, initial_attrs)

      update_attrs = %{score: 5, comment: "Excellent company after all!"}
      assert {:ok, updated_rating} = Ratings.rate_company(user, company, update_attrs)
      assert updated_rating.score == 5
      assert updated_rating.comment == "Excellent company after all!"
    end

    test "user cannot rate a company without interaction" do
      user = user_fixture(confirmed: true)
      company_admin = employer_user_fixture(confirmed: true)
      company = company_fixture(company_admin)

      attrs = %{score: 4, comment: "Great company!"}
      assert {:error, :no_interaction} = Ratings.rate_company(user, company, attrs)
    end

    test "with invalid score returns error changeset", %{user: user, company: company} do
      invalid_score_attrs = %{
        score: 0,
        comment: "some comment"
      }

      assert {:error, changeset} = Ratings.rate_company(user, company, invalid_score_attrs)
      assert "must be between 1 and 5" in errors_on(changeset).score

      invalid_score_attrs_high = %{score: 6, comment: "some comment"}
      assert {:error, changeset} = Ratings.rate_company(user, company, invalid_score_attrs_high)
      assert "must be between 1 and 5" in errors_on(changeset).score
    end
  end

  describe "rate_user/3" do
    setup do
      user = user_fixture(confirmed: true)
      company_admin = employer_user_fixture(confirmed: true)
      company = company_fixture(company_admin)
      job_posting = job_posting_fixture(company)
      job_application = job_application_fixture(user, job_posting)

      %{
        company_admin: company_admin,
        company: company,
        job_application: job_application,
        job_posting: job_posting,
        user: user
      }
    end

    test "with valid data creates a rating", %{company: company, user: user} do
      valid_attrs = %{
        score: 5,
        comment: "Excellent candidate!"
      }

      assert {:ok, %Ratings.Rating{} = rating} = Ratings.rate_user(company, user, valid_attrs)
      assert rating.score == 5
      assert rating.comment == "Excellent candidate!"
      assert rating.rater_type == "Company"
      assert rating.rater_id == company.id
      assert rating.ratee_type == "User"
      assert rating.ratee_id == user.id
    end

    test "with invalid data returns error changeset", %{company: company, user: user} do
      invalid_attrs = %{score: nil, comment: nil}
      assert {:error, %Ecto.Changeset{}} = Ratings.rate_user(company, user, invalid_attrs)
    end

    test "broadcasts a message when rating is created", %{company: company, user: user} do
      Endpoint.subscribe("rating:User:#{user.id}")

      valid_attrs = %{
        score: 5,
        comment: "broadcast test comment"
      }

      assert {:ok, %Ratings.Rating{} = rating} = Ratings.rate_user(company, user, valid_attrs)

      assert_receive %Phoenix.Socket.Broadcast{
        event: "rating_updated",
        payload: broadcasted_rating
      }

      assert broadcasted_rating.id == rating.id
      assert broadcasted_rating.comment == "broadcast test comment"
      assert broadcasted_rating.score == 5
    end

    test "company can update an existing user rating", %{company: company, user: user} do
      initial_attrs = %{score: 2, comment: "Not a great fit"}
      {:ok, _rating} = Ratings.rate_user(company, user, initial_attrs)

      update_attrs = %{score: 3, comment: "Better than we initially thought"}
      assert {:ok, updated_rating} = Ratings.rate_user(company, user, update_attrs)
      assert updated_rating.score == 3
      assert updated_rating.comment == "Better than we initially thought"
    end

    test "company cannot rate a user without interaction" do
      user = user_fixture(confirmed: true)
      company_admin = employer_user_fixture(confirmed: true)
      company = company_fixture(company_admin)

      attrs = %{score: 3, comment: "Good candidate"}
      assert {:error, :no_interaction} = Ratings.rate_user(company, user, attrs)
    end
  end

  describe "change_rating/1" do
    test "returns a rating changeset", %{rating: rating} do
      assert %Ecto.Changeset{} = Ratings.change_rating(rating)
    end

    test "returns a changeset with errors when data is invalid", %{rating: rating} do
      changeset = Ratings.change_rating(rating, %{score: 10})
      assert %{score: ["must be between 1 and 5"]} = errors_on(changeset)
    end
  end
end
