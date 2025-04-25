defmodule BemedaPersonal.RatingsTest do
  use BemedaPersonal.DataCase, async: true

  import BemedaPersonal.AccountsFixtures
  import BemedaPersonal.CompaniesFixtures
  import BemedaPersonal.JobsFixtures
  import BemedaPersonal.RatingsFixtures

  alias BemedaPersonal.Accounts
  alias BemedaPersonal.Companies
  alias BemedaPersonal.Ratings

  @invalid_attrs %{
    comment: nil,
    rater_type: nil,
    rater_id: nil,
    ratee_type: nil,
    ratee_id: nil,
    score: nil
  }

  describe "list_ratings/0" do
    test "returns all ratings" do
      rating = rating_fixture()
      assert Ratings.list_ratings() == [rating]
    end
  end

  describe "get_rating!/1" do
    test "returns the rating with given id" do
      rating = rating_fixture()
      assert Ratings.get_rating!(rating.id) == rating
    end
  end

  describe "create_rating/1" do
    test "with valid data creates a rating" do
      valid_attrs = %{
        comment: "some comment",
        rater_type: "some rater_type",
        rater_id: "7488a646-e31f-11e4-aace-600308960662",
        ratee_type: "some ratee_type",
        ratee_id: "7488a646-e31f-11e4-aace-600308960662",
        score: 4
      }

      assert {:ok, %Ratings.Rating{} = rating} = Ratings.create_rating(valid_attrs)
      assert rating.comment == "some comment"
      assert rating.rater_type == "some rater_type"
      assert rating.rater_id == "7488a646-e31f-11e4-aace-600308960662"
      assert rating.ratee_type == "some ratee_type"
      assert rating.ratee_id == "7488a646-e31f-11e4-aace-600308960662"
      assert rating.score == 4
    end

    test "with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Ratings.create_rating(@invalid_attrs)
    end
  end

  describe "update_rating/2" do
    test "with valid data updates the rating" do
      rating = rating_fixture()

      update_attrs = %{
        comment: "some updated comment",
        rater_type: "some updated rater_type",
        rater_id: "7488a646-e31f-11e4-aace-600308960668",
        ratee_type: "some updated ratee_type",
        ratee_id: "7488a646-e31f-11e4-aace-600308960668",
        score: 3
      }

      assert {:ok, %Ratings.Rating{} = rating} = Ratings.update_rating(rating, update_attrs)
      assert rating.comment == "some updated comment"
      assert rating.rater_type == "some updated rater_type"
      assert rating.rater_id == "7488a646-e31f-11e4-aace-600308960668"
      assert rating.ratee_type == "some updated ratee_type"
      assert rating.ratee_id == "7488a646-e31f-11e4-aace-600308960668"
      assert rating.score == 3
    end

    test "with invalid data returns error changeset" do
      rating = rating_fixture()
      assert {:error, %Ecto.Changeset{}} = Ratings.update_rating(rating, @invalid_attrs)
      assert rating == Ratings.get_rating!(rating.id)
    end
  end

  describe "change_rating/1" do
    test "returns a rating changeset" do
      rating = rating_fixture()
      assert %Ecto.Changeset{} = Ratings.change_rating(rating)
    end
  end

  describe "rate_company/3" do
    test "user can rate a company after applying to a job" do
      user = user_fixture(confirmed: true)
      company_admin = user_fixture(confirmed: true)
      company = company_fixture(company_admin)
      job_posting = job_posting_fixture(company)
      _job_application = job_application_fixture(user, job_posting)

      attrs = %{score: 4, comment: "Great company to work with!"}

      assert {:ok, rating} = Ratings.rate_company(user, company, attrs)
      assert rating.score == 4
      assert rating.comment == "Great company to work with!"
      assert rating.rater_type == "User"
      assert rating.rater_id == user.id
      assert rating.ratee_type == "Company"
      assert rating.ratee_id == company.id

      # Check that the company's average_rating was updated
      updated_company = Companies.get_company!(company.id)
      assert updated_company.average_rating != nil
    end

    test "user can update an existing company rating" do
      user = user_fixture(confirmed: true)
      company_admin = user_fixture(confirmed: true)
      company = company_fixture(company_admin)
      job_posting = job_posting_fixture(company)
      _job_application = job_application_fixture(user, job_posting)

      # Create initial rating
      initial_attrs = %{score: 3, comment: "Good company"}
      {:ok, _rating} = Ratings.rate_company(user, company, initial_attrs)

      # Update the rating
      update_attrs = %{score: 5, comment: "Excellent company after all!"}
      assert {:ok, updated_rating} = Ratings.rate_company(user, company, update_attrs)
      assert updated_rating.score == 5
      assert updated_rating.comment == "Excellent company after all!"

      # Check that the company's average_rating was updated
      updated_company = Companies.get_company!(company.id)
      assert updated_company.average_rating != nil
    end

    test "user cannot rate a company without interaction" do
      user = user_fixture(confirmed: true)
      company_admin = user_fixture(confirmed: true)
      company = company_fixture(company_admin)

      # No job application was created

      attrs = %{score: 4, comment: "Great company!"}
      assert {:error, :no_interaction} = Ratings.rate_company(user, company, attrs)
    end
  end

  describe "rate_user/3" do
    test "company can rate a user after they apply to a job" do
      user = user_fixture(confirmed: true)
      company_admin = user_fixture(confirmed: true)
      company = company_fixture(company_admin)
      job_posting = job_posting_fixture(company)
      _job_application = job_application_fixture(user, job_posting)

      attrs = %{score: 5, comment: "Excellent candidate!"}

      assert {:ok, rating} = Ratings.rate_user(company, user, attrs)
      assert rating.score == 5
      assert rating.comment == "Excellent candidate!"
      assert rating.rater_type == "Company"
      assert rating.rater_id == company.id
      assert rating.ratee_type == "User"
      assert rating.ratee_id == user.id

      # Check that the user's average_rating was updated
      updated_user = Accounts.get_user!(user.id)
      assert updated_user.average_rating != nil
    end

    test "company can update an existing user rating" do
      user = user_fixture(confirmed: true)
      company_admin = user_fixture(confirmed: true)
      company = company_fixture(company_admin)
      job_posting = job_posting_fixture(company)
      _job_application = job_application_fixture(user, job_posting)

      # Create initial rating
      initial_attrs = %{score: 2, comment: "Not a great fit"}
      {:ok, _rating} = Ratings.rate_user(company, user, initial_attrs)

      # Update the rating
      update_attrs = %{score: 3, comment: "Better than we initially thought"}
      assert {:ok, updated_rating} = Ratings.rate_user(company, user, update_attrs)
      assert updated_rating.score == 3
      assert updated_rating.comment == "Better than we initially thought"

      # Check that the user's average_rating was updated
      updated_user = Accounts.get_user!(user.id)
      assert updated_user.average_rating != nil
    end

    test "company cannot rate a user without interaction" do
      user = user_fixture(confirmed: true)
      company_admin = user_fixture(confirmed: true)
      company = company_fixture(company_admin)

      # No job application was created

      attrs = %{score: 3, comment: "Good candidate"}
      assert {:error, :no_interaction} = Ratings.rate_user(company, user, attrs)
    end
  end

  describe "get_average_rating/2" do
    test "calculates average rating correctly for companies" do
      company_admin = user_fixture(confirmed: true)
      company = company_fixture(company_admin)
      job_posting = job_posting_fixture(company)

      # Create three users who will rate the company
      user1 = user_fixture(confirmed: true)
      user2 = user_fixture(confirmed: true)
      user3 = user_fixture(confirmed: true)

      job_application_fixture(user1, job_posting)
      job_application_fixture(user2, job_posting)
      job_application_fixture(user3, job_posting)

      # Give ratings
      Ratings.rate_company(user1, company, %{score: 5, comment: "Excellent"})
      Ratings.rate_company(user2, company, %{score: 3, comment: "Average"})
      Ratings.rate_company(user3, company, %{score: 4, comment: "Good"})

      # Check average calculation
      avg_rating = Ratings.get_average_rating("Company", company.id)
      assert avg_rating != nil

      # Check cached value
      updated_company = Companies.get_company!(company.id)
      assert updated_company.average_rating != nil
    end

    test "calculates average rating correctly for users" do
      user = user_fixture(confirmed: true)

      # Create three companies who will rate the user
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

      # Give ratings
      Ratings.rate_user(company1, user, %{score: 2, comment: "Below average"})
      Ratings.rate_user(company2, user, %{score: 1, comment: "Poor"})
      Ratings.rate_user(company3, user, %{score: 3, comment: "Average"})

      # Check average calculation
      avg_rating = Ratings.get_average_rating("User", user.id)
      assert avg_rating != nil

      # Check cached value
      updated_user = Accounts.get_user!(user.id)
      assert updated_user.average_rating != nil
    end
  end
end
