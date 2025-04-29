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
        score: 5
      })
      |> BemedaPersonal.Ratings.create_rating()

    rating
  end
end
