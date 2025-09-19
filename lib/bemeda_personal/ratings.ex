defmodule BemedaPersonal.Ratings do
  @moduledoc """
  The Ratings context.
  """

  import Ecto.Query, warn: false

  alias BemedaPersonal.Accounts.Scope
  alias BemedaPersonal.Accounts.User
  alias BemedaPersonal.Companies.Company
  alias BemedaPersonal.JobApplications.JobApplication
  alias BemedaPersonal.Ratings.Rating
  alias BemedaPersonal.Repo
  alias BemedaPersonalWeb.Endpoint

  @type attrs :: map()
  @type changeset :: Ecto.Changeset.t()
  @type company :: Company.t()
  @type id :: Ecto.UUID.t()
  @type rating :: Rating.t()
  @type scope :: Scope.t()
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
  Gets all ratings for a specific entity as ratee with scope filtering.

  Employers can see ratings for their company and users they've interacted with.
  Job seekers can see ratings for companies they've applied to.

  ## Examples

      iex> list_ratings_by_ratee_id(scope, "User", user_id)
      [%Rating{}, ...]

      iex> list_ratings_by_ratee_id(scope, "Company", company_id)
      [%Rating{}, ...]

  """
  @spec list_ratings_by_ratee_id(scope() | nil, type(), id()) :: [rating()]
  def list_ratings_by_ratee_id(
        %Scope{user: %User{user_type: :employer}, company: %Company{id: company_id}},
        "Company",
        company_id
      ) do
    # Employer can see ratings for their own company
    Rating
    |> where([r], r.ratee_type == "Company" and r.ratee_id == ^company_id)
    |> Repo.all()
  end

  def list_ratings_by_ratee_id(
        %Scope{user: %User{user_type: :employer}, company: %Company{id: company_id}},
        "User",
        user_id
      ) do
    # Employer can see ratings for users they've interacted with
    interaction_exists_query =
      from(ja in JobApplication)
      |> join(:inner, [ja], jp in assoc(ja, :job_posting))
      |> where([ja, jp], ja.user_id == ^user_id and jp.company_id == ^company_id)
      |> select([ja], ja.id)

    case Repo.one(interaction_exists_query) do
      nil ->
        []

      _interaction ->
        Rating
        |> where([r], r.ratee_type == "User" and r.ratee_id == ^user_id)
        |> Repo.all()
    end
  end

  def list_ratings_by_ratee_id(
        %Scope{user: %User{user_type: :job_seeker, id: user_id}},
        "Company",
        company_id
      ) do
    # Job seeker can see ratings for companies they've applied to
    interaction_exists_query =
      from(ja in JobApplication)
      |> join(:inner, [ja], jp in assoc(ja, :job_posting))
      |> where([ja, jp], ja.user_id == ^user_id and jp.company_id == ^company_id)
      |> select([ja], ja.id)

    case Repo.one(interaction_exists_query) do
      nil ->
        []

      _interaction ->
        Rating
        |> where([r], r.ratee_type == "Company" and r.ratee_id == ^company_id)
        |> Repo.all()
    end
  end

  def list_ratings_by_ratee_id(
        %Scope{user: %User{user_type: :job_seeker, id: user_id}},
        "User",
        user_id
      ) do
    # Job seeker can see their own ratings
    Rating
    |> where([r], r.ratee_type == "User" and r.ratee_id == ^user_id)
    |> Repo.all()
  end

  def list_ratings_by_ratee_id(%Scope{}, _ratee_type, _ratee_id), do: []
  def list_ratings_by_ratee_id(nil, _ratee_type, _ratee_id), do: []

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
  Gets a rating by rater and ratee with scope filtering.

  Returns nil if no rating exists or not authorized to access.

  ## Examples

      iex> get_rating_by_rater_and_ratee(scope, "User", user_id, "Company", company_id)
      %Rating{}

      iex> get_rating_by_rater_and_ratee(scope, "User", user_id, "Company", non_existent_id)
      nil

  """
  @spec get_rating_by_rater_and_ratee(scope() | nil, type(), id(), type(), id()) :: rating() | nil
  def get_rating_by_rater_and_ratee(
        %Scope{user: %User{user_type: :employer}, company: %Company{id: company_id}},
        "Company",
        company_id,
        "User",
        ratee_user_id
      ) do
    # Employer can see ratings their company gave to users
    if company_has_interacted_with_user?(company_id, ratee_user_id) do
      get_rating_by_rater_and_ratee("Company", company_id, "User", ratee_user_id)
    else
      nil
    end
  end

  def get_rating_by_rater_and_ratee(
        %Scope{user: %User{user_type: :job_seeker, id: user_id}},
        "User",
        user_id,
        "Company",
        company_id
      ) do
    # Job seeker can see ratings they gave to companies
    if user_has_interacted_with_company?(user_id, company_id) do
      get_rating_by_rater_and_ratee("User", user_id, "Company", company_id)
    else
      nil
    end
  end

  def get_rating_by_rater_and_ratee(%Scope{}, _rater_type, _rater_id, _ratee_type, _ratee_id),
    do: nil

  def get_rating_by_rater_and_ratee(nil, _rater_type, _rater_id, _ratee_type, _ratee_id), do: nil

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
    if user_has_interacted_with_company?(user.id, company.id) do
      rating_attrs = %{
        comment: attrs.comment,
        ratee_id: company.id,
        ratee_type: "Company",
        rater_id: user.id,
        rater_type: "User",
        score: attrs.score
      }

      create_or_update_rating(rating_attrs)
    else
      {:error, :no_interaction}
    end
  end

  @doc """
  Creates or updates a rating from a user to a company with scope verification.

  Returns an error if the user has not interacted with the company or is not authorized.

  ## Examples

      iex> rate_company(scope, user, company, %{score: 5, comment: "Great company!"})
      {:ok, %Rating{}}

      iex> rate_company(scope, user, company, %{score: 5, comment: "Great company!"})
      {:error, :no_interaction}

  """
  @spec rate_company(scope() | nil, user(), company(), attrs()) ::
          {:ok, rating()} | {:error, changeset() | atom()}
  def rate_company(
        %Scope{user: %User{user_type: :job_seeker, id: user_id}},
        %User{id: user_id} = user,
        %Company{} = company,
        attrs
      ) do
    if user_has_interacted_with_company?(user.id, company.id) do
      rating_attrs = %{
        comment: attrs.comment,
        ratee_id: company.id,
        ratee_type: "Company",
        rater_id: user.id,
        rater_type: "User",
        score: attrs.score
      }

      create_or_update_rating(rating_attrs)
    else
      {:error, :no_interaction}
    end
  end

  def rate_company(%Scope{}, _user, _company, _attrs), do: {:error, :unauthorized}
  def rate_company(nil, _user, _company, _attrs), do: {:error, :unauthorized}

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
    if company_has_interacted_with_user?(company.id, user.id) do
      rating_attrs = %{
        comment: attrs.comment,
        ratee_id: user.id,
        ratee_type: "User",
        rater_id: company.id,
        rater_type: "Company",
        score: attrs.score
      }

      create_or_update_rating(rating_attrs)
    else
      {:error, :no_interaction}
    end
  end

  @doc """
  Creates or updates a rating from a company to a user with scope verification.

  Returns an error if the company has not interacted with the user or is not authorized.

  ## Examples

      iex> rate_user(scope, company, user, %{score: 5, comment: "Great candidate!"})
      {:ok, %Rating{}}

      iex> rate_user(scope, company, user, %{score: 5, comment: "Great candidate!"})
      {:error, :no_interaction}

  """
  @spec rate_user(scope() | nil, company(), user(), attrs()) ::
          {:ok, rating()} | {:error, changeset() | atom()}
  def rate_user(
        %Scope{user: %User{user_type: :employer}, company: %Company{id: company_id}},
        %Company{id: company_id} = company,
        %User{} = user,
        attrs
      ) do
    if company_has_interacted_with_user?(company.id, user.id) do
      rating_attrs = %{
        comment: attrs.comment,
        ratee_id: user.id,
        ratee_type: "User",
        rater_id: company.id,
        rater_type: "Company",
        score: attrs.score
      }

      create_or_update_rating(rating_attrs)
    else
      {:error, :no_interaction}
    end
  end

  def rate_user(%Scope{}, _company, _user, _attrs), do: {:error, :unauthorized}
  def rate_user(nil, _company, _user, _attrs), do: {:error, :unauthorized}

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

  defp user_has_interacted_with_company?(user_id, company_id) do
    from(ja in JobApplication)
    |> join(:inner, [ja], jp in assoc(ja, :job_posting))
    |> where([ja, jp], ja.user_id == ^user_id and jp.company_id == ^company_id)
    |> Repo.exists?()
  end

  defp company_has_interacted_with_user?(company_id, user_id) do
    user_has_interacted_with_company?(user_id, company_id)
  end
end
