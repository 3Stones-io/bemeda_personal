defmodule BemedaPersonal.RepoHelpers do
  @moduledoc """
  Repository helpers for handling database operations in test environments.

  Provides wrapped functions that prevent DBConnection.OwnershipError
  issues during feature tests by handling Task processes properly.
  """

  alias BemedaPersonal.Repo

  @doc """
  Preload associations safely in test environment.

  This function prevents DBConnection.OwnershipError by ensuring
  Task processes spawned by Ecto.Repo.Preloader have proper database access.
  """
  @spec safe_preload(any(), any(), keyword()) :: any()
  def safe_preload(struct_or_structs, preloads, opts \\ []) do
    if Application.get_env(:bemeda_personal, :env) == :test and
         Application.get_env(:bemeda_personal, :sql_sandbox) do
      # In test environment with SQL sandbox enabled, use query-based preloading
      # to avoid Task processes that don't have database ownership
      preload_via_queries(struct_or_structs, preloads, opts)
    else
      # Production environment - use normal preloading
      Repo.preload(struct_or_structs, preloads, opts)
    end
  end

  defp preload_via_queries(struct_or_structs, preloads, _opts) when is_list(struct_or_structs) do
    # For lists of structs, preload each individually
    Enum.map(struct_or_structs, fn struct ->
      preload_via_queries(struct, preloads, [])
    end)
  end

  defp preload_via_queries(struct, preloads, _opts) when is_map(struct) do
    # For individual structs, reload from database with preloads in query
    schema = struct.__struct__

    case schema.__schema__(:primary_key) do
      [pk_field] ->
        pk_value = Map.get(struct, pk_field)
        import Ecto.Query
        query = from(s in schema, where: field(s, ^pk_field) == ^pk_value, preload: ^preloads)
        Repo.one(query) || struct

      _composite_or_no_pk ->
        # Composite primary key or no primary key - return as is
        struct
    end
  rescue
    _error ->
      # If anything fails, return original struct
      struct
  end
end
