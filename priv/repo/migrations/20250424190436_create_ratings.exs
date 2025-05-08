defmodule BemedaPersonal.Repo.Migrations.CreateRatings do
  use Ecto.Migration

  def change do
    create table(:ratings, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :rater_type, :string, null: false
      add :rater_id, :uuid, null: false
      add :ratee_type, :string, null: false
      add :ratee_id, :uuid, null: false
      add :score, :integer, null: false
      add :comment, :text

      timestamps(type: :utc_datetime)
    end

    create index(:ratings, [:rater_type, :rater_id])
    create index(:ratings, [:ratee_type, :ratee_id])

    create unique_index(:ratings, [:rater_type, :rater_id, :ratee_type, :ratee_id],
             name: :ratings_rater_ratee_unique_index
           )
  end
end
