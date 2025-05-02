defmodule BemedaPersonal.Ratings do
  @moduledoc """
  The Ratings context.
  """

  import Ecto.Query, warn: false

  alias BemedaPersonal.Accounts.User
  alias BemedaPersonal.Companies.Company
  alias BemedaPersonal.Jobs.JobApplication
  alias BemedaPersonal.Ratings.Rating
  alias BemedaPersonal.Repo
  alias BemedaPersonalWeb.Endpoint

  @type attrs :: map()
  @type changeset :: Ecto.Changeset.t()
  @type company :: Company.t()
  @type id :: Ecto.UUID.t()
  @type rating :: Rating.t()
  @type type :: String.t()
  @type user :: User.t()

  @doc """
  Gets all ratings for a specific entity as ratee.

  ## Examples

      iex> list_ratings_by_ratee_id("User", user_id)
      [%Rating{}, ...]

      iex> list_ratings_by_ratee_id("Company", company_id)
      [%Rating{}, ...]

  """
  @spec list_ratings_by_ratee_id(type(), id()) :: [rating()]
  def list_ratings_by_ratee_id(ratee_type, ratee_id) do
    Rating
    |> where([r], r.ratee_type == ^ratee_type and r.ratee_id == ^ratee_id)
    |> Repo.all()
  end

  @doc """
  Gets a rating by rater and ratee.

  Returns nil if no rating exists.

  ## Examples

      iex> get_rating_by_rater_and_ratee("User", user_id, "Company", company_id)
      %Rating{}

      iex> get_rating_by_rater_and_ratee("User", user_id, "Company", non_existent_id)
      nil

  """
  @spec get_rating_by_rater_and_ratee(type(), id(), type(), id()) :: rating() | nil
  def get_rating_by_rater_and_ratee(rater_type, rater_id, ratee_type, ratee_id) do
    Rating
    |> where(
      [r],
      r.rater_type == ^rater_type and
        r.rater_id == ^rater_id and
        r.ratee_type == ^ratee_type and
        r.ratee_id == ^ratee_id
    )
    |> Repo.one()
  end

  @doc """
  Creates or updates a rating from a user to a company.

  Returns an error if the user has not interacted with the company.

  ## Examples

      iex> rate_company(user, company, %{score: 5, comment: "Great company!"})
      {:ok, %Rating{}}

      iex> rate_company(user, company, %{score: 5, comment: "Great company!"})
      {:error, :no_interaction}

  """
  @spec rate_company(user(), company(), attrs()) ::
          {:ok, rating()} | {:error, changeset() | atom()}
  def rate_company(%User{} = user, %Company{} = company, attrs) do
    if user_has_interacted_with_company?(user, company) do
      rating_attrs = %{
        rater_type: "User",
        rater_id: user.id,
        ratee_type: "Company",
        ratee_id: company.id,
        score: attrs.score,
        comment: attrs.comment
      }

      create_or_update_rating(rating_attrs)
    else
      {:error, :no_interaction}
    end
  end

  @doc """
  Creates or updates a rating from a company to a user.

  Returns an error if the company has not interacted with the user.

  ## Examples

      iex> rate_user(company, user, %{score: 5, comment: "Great candidate!"})
      {:ok, %Rating{}}

      iex> rate_user(company, user, %{score: 5, comment: "Great candidate!"})
      {:error, :no_interaction}

  """
  @spec rate_user(company(), user(), attrs()) :: {:ok, rating()} | {:error, changeset() | atom()}
  def rate_user(%Company{} = company, %User{} = user, attrs) do
    if company_has_interacted_with_user?(company, user) do
      rating_attrs = %{
        rater_type: "Company",
        rater_id: company.id,
        ratee_type: "User",
        ratee_id: user.id,
        score: attrs.score,
        comment: attrs.comment
      }

      create_or_update_rating(rating_attrs)
    else
      {:error, :no_interaction}
    end
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking rating changes.

  ## Examples

      iex> change_rating(rating)
      %Ecto.Changeset{data: %Rating{}}

  """
  @spec change_rating(rating(), attrs()) :: changeset()
  def change_rating(%Rating{} = rating, attrs \\ %{}) do
    Rating.changeset(rating, attrs)
  end

  defp create_or_update_rating(attrs) do
    changeset = Rating.changeset(%Rating{}, attrs)

    result =
      Repo.insert(changeset,
        on_conflict: {:replace, [:score, :comment, :updated_at]},
        conflict_target: [:rater_type, :rater_id, :ratee_type, :ratee_id],
        returning: true
      )

    case result do
      {:ok, rating} ->
        topic = "rating:#{rating.ratee_type}:#{rating.ratee_id}"
        Endpoint.broadcast(topic, "rating_updated", rating)

        {:ok, rating}

      error ->
        error
    end
  end

  defp user_has_interacted_with_company?(user, company) do
    from(ja in JobApplication)
    |> join(:inner, [ja], jp in assoc(ja, :job_posting))
    |> where([ja, jp], ja.user_id == ^user.id and jp.company_id == ^company.id)
    |> Repo.exists?()
  end

  defp company_has_interacted_with_user?(company, user) do
    user_has_interacted_with_company?(user, company)
  end
end
