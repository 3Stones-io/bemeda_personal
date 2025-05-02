defmodule BemedaPersonal.RatingsTest do
  use BemedaPersonal.DataCase, async: true

  import BemedaPersonal.AccountsFixtures
  import BemedaPersonal.CompaniesFixtures
  import BemedaPersonal.JobsFixtures
  import BemedaPersonal.RatingsFixtures

  alias BemedaPersonal.Ratings

  @invalid_attrs %{
    comment: nil,
    rater_type: nil,
    rater_id: nil,
    ratee_type: nil,
    ratee_id: nil,
    score: nil
  }

  setup do
    user = user_fixture(confirmed: true)
    company_admin = user_fixture(confirmed: true)
    company = company_fixture(company_admin)

    rating =
      rating_fixture(
        ratee_id: user.id,
        ratee_type: "User",
        rater_id: company.id,
        rater_type: "Company"
      )

    %{rating: rating}
  end

  describe "list_ratings/0" do
    test "returns all ratings", %{rating: rating} do
      assert Ratings.list_ratings() == [rating]
    end
  end

  describe "get_rating!/1" do
    test "returns the rating with given id", %{rating: rating} do
      assert Ratings.get_rating!(rating.id) == rating
    end

    test "raises an error if the rating does not exist" do
      assert_raise Ecto.NoResultsError, fn ->
        Ratings.get_rating!(Ecto.UUID.generate())
      end
    end
  end

  describe "create_rating/1" do
    test "with valid data creates a rating" do
      user = user_fixture(confirmed: true)
      company_admin = user_fixture(confirmed: true)
      company = company_fixture(company_admin)

      valid_attrs = %{
        comment: "some comment",
        rater_type: "Company",
        rater_id: company.id,
        ratee_type: "User",
        ratee_id: user.id,
        score: 4
      }

      assert {:ok, %Ratings.Rating{} = rating} = Ratings.create_rating(valid_attrs)
      assert rating.comment == "some comment"
      assert rating.rater_type == "Company"
      assert rating.rater_id == company.id
      assert rating.ratee_type == "User"
      assert rating.ratee_id == user.id
      assert rating.score == 4
    end

    test "with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Ratings.create_rating(@invalid_attrs)
    end
  end

  describe "update_rating/2" do
    test "with valid data updates the rating", %{rating: rating} do
      update_attrs = %{
        comment: "some updated comment",
        rater_type: "Company",
        rater_id: rating.rater_id,
        ratee_type: "User",
        ratee_id: rating.ratee_id,
        score: 3
      }

      assert {:ok, %Ratings.Rating{} = rating} = Ratings.update_rating(rating, update_attrs)
      assert rating.comment == "some updated comment"
      assert rating.rater_type == "Company"
      assert rating.rater_id == rating.rater_id
      assert rating.ratee_type == "User"
      assert rating.ratee_id == rating.ratee_id
      assert rating.score == 3
    end

    test "with invalid data returns error changeset", %{rating: rating} do
      assert {:error, %Ecto.Changeset{}} = Ratings.update_rating(rating, @invalid_attrs)
      assert rating == Ratings.get_rating!(rating.id)
    end
  end

  describe "change_rating/1" do
    test "returns a rating changeset", %{rating: rating} do
      assert %Ecto.Changeset{} = Ratings.change_rating(rating)
    end
  end

  describe "rate_company/3" do
    setup do
      user = user_fixture(confirmed: true)
      company_admin = user_fixture(confirmed: true)
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

    test "user can rate a company after applying to a job", %{user: user, company: company} do
      attrs = %{score: 4, comment: "Great company to work with!"}

      assert {:ok, rating} = Ratings.rate_company(user, company, attrs)
      assert rating.score == 4
      assert rating.comment == "Great company to work with!"
      assert rating.rater_type == "User"
      assert rating.rater_id == user.id
      assert rating.ratee_type == "Company"
      assert rating.ratee_id == company.id
    end

    test "user can update an existing company rating", %{user: user, company: company} do
      initial_attrs = %{score: 3, comment: "Good company"}
      {:ok, _rating} = Ratings.rate_company(user, company, initial_attrs)

      update_attrs = %{score: 5, comment: "Excellent company after all!"}
      assert {:ok, updated_rating} = Ratings.rate_company(user, company, update_attrs)
      assert updated_rating.score == 5
      assert updated_rating.comment == "Excellent company after all!"
    end
  end

  describe "rate_company/3 with no interaction" do
    test "user cannot rate a company without interaction" do
      user = user_fixture(confirmed: true)
      company_admin = user_fixture(confirmed: true)
      company = company_fixture(company_admin)

      attrs = %{score: 4, comment: "Great company!"}
      assert {:error, :no_interaction} = Ratings.rate_company(user, company, attrs)
    end
  end

  describe "rate_user/3" do
    setup do
      user = user_fixture(confirmed: true)
      company_admin = user_fixture(confirmed: true)
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

    test "company can rate a user after they apply to a job", %{company: company, user: user} do
      attrs = %{score: 5, comment: "Excellent candidate!"}

      assert {:ok, rating} = Ratings.rate_user(company, user, attrs)
      assert rating.score == 5
      assert rating.comment == "Excellent candidate!"
      assert rating.rater_type == "Company"
      assert rating.rater_id == company.id
      assert rating.ratee_type == "User"
      assert rating.ratee_id == user.id
    end

    test "company can update an existing user rating", %{company: company, user: user} do
      initial_attrs = %{score: 2, comment: "Not a great fit"}
      {:ok, _rating} = Ratings.rate_user(company, user, initial_attrs)

      update_attrs = %{score: 3, comment: "Better than we initially thought"}
      assert {:ok, updated_rating} = Ratings.rate_user(company, user, update_attrs)
      assert updated_rating.score == 3
      assert updated_rating.comment == "Better than we initially thought"
    end
  end

  describe "rate_user/3 with no interaction" do
    test "company cannot rate a user without interaction" do
      user = user_fixture(confirmed: true)
      company_admin = user_fixture(confirmed: true)
      company = company_fixture(company_admin)

      attrs = %{score: 3, comment: "Good candidate"}
      assert {:error, :no_interaction} = Ratings.rate_user(company, user, attrs)
    end
  end

  describe "get_average_rating/2" do
    test "calculates average rating correctly for companies" do
      company_admin = user_fixture(confirmed: true)
      company = company_fixture(company_admin)
      job_posting = job_posting_fixture(company)

      user1 = user_fixture(confirmed: true)
      user2 = user_fixture(confirmed: true)
      user3 = user_fixture(confirmed: true)

      job_application_fixture(user1, job_posting)
      job_application_fixture(user2, job_posting)
      job_application_fixture(user3, job_posting)

      Ratings.rate_company(user1, company, %{score: 5, comment: "Excellent"})
      Ratings.rate_company(user2, company, %{score: 3, comment: "Average"})
      Ratings.rate_company(user3, company, %{score: 4, comment: "Good"})

      avg_rating = Ratings.get_average_rating("Company", company.id)
      assert avg_rating != nil
    end

    test "calculates average rating correctly for users" do
      user = user_fixture(confirmed: true)

      admin1 = user_fixture(confirmed: true)
      admin2 = user_fixture(confirmed: true)
      admin3 = user_fixture(confirmed: true)

      company1 = company_fixture(admin1)
      company2 = company_fixture(admin2)
      company3 = company_fixture(admin3)

      job_posting1 = job_posting_fixture(company1)
      job_posting2 = job_posting_fixture(company2)
      job_posting3 = job_posting_fixture(company3)

      job_application_fixture(user, job_posting1)
      job_application_fixture(user, job_posting2)
      job_application_fixture(user, job_posting3)

      Ratings.rate_user(company1, user, %{score: 2, comment: "Below average"})
      Ratings.rate_user(company2, user, %{score: 1, comment: "Poor"})
      Ratings.rate_user(company3, user, %{score: 3, comment: "Average"})

      assert Ratings.get_average_rating("User", user.id) == Decimal.new("2.0000000000000000")
    end
  end
end
