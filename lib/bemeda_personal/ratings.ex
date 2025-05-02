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
  alias Phoenix.PubSub

  @type attrs :: map()
  @type changeset :: Ecto.Changeset.t()
  @type company :: Company.t()
  @type id :: Ecto.UUID.t()
  @type rating :: Rating.t()
  @type type :: String.t()
  @type user :: User.t()

  @rating_topic "rating"

  @doc """
  Returns the list of ratings.

  ## Examples

      iex> list_ratings()
      [%Rating{}, ...]

  """
  @spec list_ratings() :: [rating()]
  def list_ratings do
    Repo.all(Rating)
  end

  @doc """
  Gets a single rating.

  Raises `Ecto.NoResultsError` if the Rating does not exist.

  ## Examples

      iex> get_rating!(123)
      %Rating{}

      iex> get_rating!(456)
      ** (Ecto.NoResultsError)

  """
  @spec get_rating!(id()) :: rating() | no_return()
  def get_rating!(id), do: Repo.get!(Rating, id)

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
  Gets all ratings for a specific entity as ratee.

  ## Examples

      iex> get_ratings_for_ratee("User", user_id)
      [%Rating{}, ...]

      iex> get_ratings_for_ratee("Company", company_id)
      [%Rating{}, ...]

  """
  @spec get_ratings_for_ratee(type(), id()) :: [rating()]
  def get_ratings_for_ratee(ratee_type, ratee_id) do
    Rating
    |> where([r], r.ratee_type == ^ratee_type and r.ratee_id == ^ratee_id)
    |> Repo.all()
  end

  @doc """
  Gets all ratings by a specific entity as rater.

  ## Examples

      iex> get_ratings_by_rater("User", user_id)
      [%Rating{}, ...]

      iex> get_ratings_by_rater("Company", company_id)
      [%Rating{}, ...]

  """
  @spec get_ratings_by_rater(type(), id()) :: [rating()]
  def get_ratings_by_rater(rater_type, rater_id) do
    Rating
    |> where([r], r.rater_type == ^rater_type and r.rater_id == ^rater_id)
    |> Repo.all()
  end

  @doc """
  Calculates the average rating for a specific entity.

  ## Examples

      iex> get_average_rating("User", user_id)
      #Decimal<4.5>

      iex> get_average_rating("Company", company_id)
      #Decimal<3.0>

  """
  @spec get_average_rating(type(), id()) :: Decimal.t() | nil
  def get_average_rating(ratee_type, ratee_id) do
    query =
      from r in Rating,
        where: r.ratee_type == ^ratee_type and r.ratee_id == ^ratee_id,
        select: avg(r.score)

    Repo.one!(query)
  end

  @doc """
  Creates a rating.

  ## Examples

      iex> create_rating(%{field: value})
      {:ok, %Rating{}}

      iex> create_rating(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  @spec create_rating(attrs()) :: {:ok, rating()} | {:error, changeset()}
  def create_rating(attrs \\ %{}) do
    result =
      %Rating{}
      |> Rating.changeset(attrs)
      |> Repo.insert()

    case result do
      {:ok, rating} ->
        broadcast_event(
          "#{@rating_topic}:#{rating.ratee_type}:#{rating.ratee_id}",
          {:rating_created, rating}
        )

        {:ok, rating}

      error ->
        error
    end
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
      existing_rating = get_rating_by_rater_and_ratee("User", user.id, "Company", company.id)

      if existing_rating do
        update_rating(existing_rating, attrs)
      else
        create_rating(%{
          rater_type: "User",
          rater_id: user.id,
          ratee_type: "Company",
          ratee_id: company.id,
          score: attrs.score,
          comment: attrs.comment
        })
      end
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
      existing_rating = get_rating_by_rater_and_ratee("Company", company.id, "User", user.id)

      if existing_rating do
        update_rating(existing_rating, attrs)
      else
        create_rating(%{
          rater_type: "Company",
          rater_id: company.id,
          ratee_type: "User",
          ratee_id: user.id,
          score: attrs.score,
          comment: attrs.comment
        })
      end
    else
      {:error, :no_interaction}
    end
  end

  @doc """
  Updates a rating.

  ## Examples

      iex> update_rating(rating, %{field: new_value})
      {:ok, %Rating{}}

      iex> update_rating(rating, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  @spec update_rating(rating(), attrs()) :: {:ok, rating()} | {:error, changeset()}
  def update_rating(%Rating{} = rating, attrs) do
    result =
      rating
      |> Rating.changeset(attrs)
      |> Repo.update()

    case result do
      {:ok, updated_rating} ->
        broadcast_event(
          "#{@rating_topic}:#{rating.ratee_type}:#{rating.ratee_id}",
          {:rating_updated, updated_rating}
        )

        {:ok, updated_rating}

      error ->
        error
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

  defp user_has_interacted_with_company?(user, company) do
    from(ja in JobApplication)
    |> join(:inner, [ja], jp in assoc(ja, :job_posting))
    |> where([ja, jp], ja.user_id == ^user.id and jp.company_id == ^company.id)
    |> Repo.exists?()
  end

  defp company_has_interacted_with_user?(company, user) do
    user_has_interacted_with_company?(user, company)
  end

  defp broadcast_event(topic, message) do
    PubSub.broadcast(BemedaPersonal.PubSub, topic, message)
  end
end
