defmodule BemedaPersonal.RatingsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `BemedaPersonal.Ratings` context.
  """

  import BemedaPersonal.AccountsFixtures
  import BemedaPersonal.CompaniesFixtures

  alias BemedaPersonal.Ratings.Rating
  alias BemedaPersonal.Repo

  @spec rating_fixture(map()) :: Rating.t()
  def rating_fixture(attrs \\ %{}) do
    {:ok, rating} =
      attrs
      |> Enum.into(valid_attrs(attrs))
      |> then(&Rating.changeset(%Rating{}, &1))
      |> Repo.insert()

    rating
  end

  defp valid_attrs(attrs) do
    ratee_id = attrs[:ratee_id] || user_fixture().id
    rater_id = attrs[:rater_id] || company_fixture(user_fixture()).id

    %{
      comment: "some comment",
      rater_id: rater_id,
      rater_type: "Company",
      ratee_id: ratee_id,
      ratee_type: "User",
      score: 5
    }
  end
end
