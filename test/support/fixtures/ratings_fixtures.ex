defmodule BemedaPersonal.RatingsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `BemedaPersonal.Ratings` context.
  """

  @spec rating_fixture(map()) :: BemedaPersonal.Ratings.Rating.t()
  def rating_fixture(attrs \\ %{}) do
    {:ok, rating} =
      attrs
      |> Enum.into(%{
        comment: "some comment",
        ratee_id: "7488a646-e31f-11e4-aace-600308960662",
        ratee_type: "some ratee_type",
        rater_id: "7488a646-e31f-11e4-aace-600308960662",
        rater_type: "some rater_type",
        score: 5
      })
      |> BemedaPersonal.Ratings.create_rating()

    rating
  end
end
