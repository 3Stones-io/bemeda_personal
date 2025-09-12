defmodule BemedaPersonal.Repo.Migrations.MigrateUserFieldsToEmbeddedSchemas do
  use Ecto.Migration

  import Ecto.Query

  def up do
    alter table(:users) do
      add :address, :map
      add :profile, :map
      add :work_profile, :map
    end

    flush()

    migrate_existing_data()

    alter table(:users) do
      remove :first_name
      remove :last_name
      remove :date_of_birth
      remove :phone
      remove :gender
      remove :street
      remove :city
      remove :zip_code
      remove :country
      remove :department
      remove :medical_role
    end
  end

  def down do
    alter table(:users) do
      add :first_name, :string
      add :last_name, :string
      add :date_of_birth, :date
      add :phone, :string
      add :gender, :string
      add :street, :string
      add :city, :string
      add :zip_code, :string
      add :country, :string
      add :department, :string
      add :medical_role, :string
    end

    flush()

    restore_existing_data()

    alter table(:users) do
      remove :address
      remove :profile
      remove :work_profile
    end
  end

  defp migrate_existing_data do
    users =
      repo().all(
        from(u in "users",
          select: %{
            id: u.id,
            first_name: u.first_name,
            last_name: u.last_name,
            date_of_birth: u.date_of_birth,
            phone: u.phone,
            gender: u.gender,
            street: u.street,
            city: u.city,
            zip_code: u.zip_code,
            country: u.country,
            department: u.department,
            medical_role: u.medical_role
          }
        )
      )

    Enum.each(users, fn user ->
      address = build_address_map(user)
      profile = build_profile_map(user)
      work_profile = build_work_profile_map(user)

      query = from(u in "users", where: u.id == ^user.id)

      repo().update_all(query,
        set: [
          address: address,
          profile: profile,
          work_profile: work_profile
        ]
      )
    end)
  end

  defp restore_existing_data do
    users =
      repo().all(
        from(u in "users",
          select: %{
            id: u.id,
            address: u.address,
            profile: u.profile,
            work_profile: u.work_profile
          }
        )
      )

    Enum.each(users, fn user ->
      address = user.address || %{}
      profile = user.profile || %{}
      work_profile = user.work_profile || %{}

      query = from(u in "users", where: u.id == ^user.id)

      repo().update_all(query,
        set: [
          first_name: profile["first_name"],
          last_name: profile["last_name"],
          date_of_birth: profile["date_of_birth"],
          phone: profile["phone"],
          gender: profile["gender"],
          street: address["street"],
          city: address["city"],
          zip_code: address["zip_code"],
          country: address["country"],
          department: work_profile["department"],
          medical_role: work_profile["medical_role"]
        ]
      )
    end)
  end

  defp build_address_map(user) do
    fields = %{
      "street" => user.street,
      "city" => user.city,
      "zip_code" => user.zip_code,
      "country" => user.country
    }

    if Enum.any?(fields, fn {_k, v} -> v != nil end) do
      fields
    else
      nil
    end
  end

  defp build_profile_map(user) do
    fields = %{
      "first_name" => user.profile.first_name,
      "last_name" => user.profile.last_name,
      "date_of_birth" => user.date_of_birth,
      "phone" => user.phone,
      "gender" => user.gender
    }

    if Enum.any?(fields, fn {_k, v} -> v != nil end) do
      fields
    else
      nil
    end
  end

  defp build_work_profile_map(user) do
    fields = %{
      "department" => user.department,
      "medical_role" => user.medical_role
    }

    if Enum.any?(fields, fn {_k, v} -> v != nil end) do
      fields
    else
      nil
    end
  end
end
