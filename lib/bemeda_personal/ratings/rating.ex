defmodule BemedaPersonal.Ratings.Rating do
  @moduledoc false

  use Ecto.Schema

  import Ecto.Changeset

  @type attrs :: map()
  @type changeset :: Ecto.Changeset.t()
  @type t :: %__MODULE__{}

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  # TODO: Set up polymorphic associations properly to enforce database constraints
  # https://hexdocs.pm/ecto/polymorphic-associations-with-many-to-many.html

  schema "ratings" do
    field :comment, :string
    field :rater_type, :string
    field :rater_id, Ecto.UUID
    field :ratee_type, :string
    field :ratee_id, Ecto.UUID
    field :score, :integer

    timestamps(type: :utc_datetime)
  end

  @spec changeset(t(), attrs()) :: changeset()
  def changeset(rating, attrs) do
    rating
    |> cast(attrs, [:rater_type, :rater_id, :ratee_type, :ratee_id, :score, :comment])
    |> validate_required([:rater_type, :rater_id, :ratee_type, :ratee_id, :score])
    |> validate_inclusion(:score, 1..5, message: "must be between 1 and 5")
    |> validate_length(:comment, max: 1000)
    |> unique_constraint([:rater_type, :rater_id, :ratee_type, :ratee_id],
      name: :ratings_rater_ratee_unique_index,
      message: "You can only rate this entity once"
    )
  end
end
