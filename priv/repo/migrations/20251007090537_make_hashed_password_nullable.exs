defmodule BemedaPersonal.Repo.Migrations.MakeHashedPasswordNullable do
  use Ecto.Migration

  def up do
    alter table(:users) do
      modify :hashed_password, :string, null: true
    end
  end

  def down do
    execute "DELETE FROM users WHERE hashed_password IS NULL"

    alter table(:users) do
      modify :hashed_password, :string, null: false
    end
  end
end
