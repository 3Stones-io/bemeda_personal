defmodule BemedaPersonalWeb.RatingComponentsTest do
  use BemedaPersonalWeb.ConnCase, async: true
  import Phoenix.LiveViewTest

  alias BemedaPersonalWeb.RatingComponents

  describe "rating_display/1" do
    test "renders rating with integer score" do
      html =
        render_component(&RatingComponents.rating_display/1, %{
          id: "test-rating",
          entity_id: "123",
          entity_type: "Test",
          average_rating: 4
        })

      assert html =~ "test-rating"
      assert html =~ "fill-current"
      assert html =~ "4"
    end

    test "renders rating with Decimal score" do
      html =
        render_component(&RatingComponents.rating_display/1, %{
          id: "test-rating",
          entity_id: "123",
          entity_type: "Test",
          average_rating: Decimal.new("4.5")
        })

      assert html =~ "test-rating"
      assert html =~ "fill-current"
      assert html =~ "4.5"
    end

    test "renders rating with float score" do
      html =
        render_component(&RatingComponents.rating_display/1, %{
          id: "test-rating",
          entity_id: "123",
          entity_type: "Test",
          average_rating: 3.7
        })

      assert html =~ "test-rating"
      assert html =~ "fill-current"
      assert html =~ "3.7"
    end

    test "renders rating with different size options" do
      # Small size
      small_html =
        render_component(&RatingComponents.rating_display/1, %{
          id: "test-rating-sm",
          entity_id: "123",
          entity_type: "Test",
          average_rating: 5,
          size: "sm"
        })

      assert small_html =~ "test-rating-sm"
      assert small_html =~ "w-4 h-4"

      # Large size
      large_html =
        render_component(&RatingComponents.rating_display/1, %{
          id: "test-rating-lg",
          entity_id: "123",
          entity_type: "Test",
          average_rating: 5,
          size: "lg"
        })

      assert large_html =~ "test-rating-lg"
      assert large_html =~ "w-6 h-6"

      # Default (medium) size
      medium_html =
        render_component(&RatingComponents.rating_display/1, %{
          id: "test-rating-md",
          entity_id: "123",
          entity_type: "Test",
          average_rating: 5,
          size: "md"
        })

      assert medium_html =~ "test-rating-md"
      assert medium_html =~ "w-5 h-5"
    end

    test "renders rating with rate button when can_rate is true" do
      html =
        render_component(&RatingComponents.rating_display/1, %{
          id: "test-rating",
          entity_id: "123",
          entity_type: "Test",
          average_rating: 4,
          can_rate: true
        })

      assert html =~ "test-rating"
      assert html =~ "Rate"
    end

    test "renders rating with update button when current_user_rating is present" do
      html =
        render_component(&RatingComponents.rating_display/1, %{
          id: "test-rating",
          entity_id: "123",
          entity_type: "Test",
          average_rating: 4,
          can_rate: true,
          current_user_rating: %{score: 3, comment: "Good"}
        })

      assert html =~ "test-rating"
      assert html =~ "Update Rating"
    end

    test "includes phx-update attribute for live updates" do
      html =
        render_component(&RatingComponents.rating_display/1, %{
          id: "test-rating",
          entity_id: "123",
          entity_type: "Test",
          average_rating: 4
        })

      assert html =~ ~s(phx-update="replace")
    end
  end

  describe "rating_form/1" do
    test "renders form with current rating" do
      html =
        render_component(&RatingComponents.rating_form/1, %{
          id: "test-form",
          entity_id: "123",
          entity_type: "Test",
          entity_name: "Test Entity",
          current_rating: %{score: 4, comment: "Very good service"}
        })

      assert html =~ "test-form"
      assert html =~ "Rate Test Entity"
      assert html =~ "score-4"
      assert html =~ "Very good service"
    end

    test "renders form without current rating" do
      html =
        render_component(&RatingComponents.rating_form/1, %{
          id: "test-form",
          entity_id: "123",
          entity_type: "Test",
          entity_name: "Test Entity"
        })

      assert html =~ "test-form"
      assert html =~ "Rate Test Entity"
      # Default score should be 5
      assert html =~ "score-5"
    end
  end
end
