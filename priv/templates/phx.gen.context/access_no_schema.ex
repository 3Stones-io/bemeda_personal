  alias <%= inspect schema.module %>

  @type attrs :: map()
  @type id :: binary()
  @type t :: <%= inspect schema.alias %>.t()

  @doc """
  Returns the list of <%= schema.plural %>.

  ## Examples

      iex> list_<%= schema.plural %>()
      [%<%= inspect schema.alias %>{}, ...]

  """
  @spec list_<%= schema.plural %>() :: [t()]
  def list_<%= schema.plural %> do
    raise "TODO"
  end

  @doc """
  Gets a single <%= schema.singular %>.

  Raises if the <%= schema.human_singular %> does not exist.

  ## Examples

      iex> get_<%= schema.singular %>!(123)
      %<%= inspect schema.alias %>{}

  """
  @spec get_<%= schema.singular %>!(id()) :: t() | no_return()
  def get_<%= schema.singular %>!(id), do: raise "TODO"

  @doc """
  Creates a <%= schema.singular %>.

  ## Examples

      iex> create_<%= schema.singular %>(%{field: value})
      {:ok, %<%= inspect schema.alias %>{}}

      iex> create_<%= schema.singular %>(%{field: bad_value})
      {:error, ...}

  """
  @spec create_<%= schema.singular %>(attrs()) :: {:ok, t()} | {:error, term()}
  def create_<%= schema.singular %>(attrs \\ %{}) do
    raise "TODO"
  end

  @doc """
  Updates a <%= schema.singular %>.

  ## Examples

      iex> update_<%= schema.singular %>(<%= schema.singular %>, %{field: new_value})
      {:ok, %<%= inspect schema.alias %>{}}

      iex> update_<%= schema.singular %>(<%= schema.singular %>, %{field: bad_value})
      {:error, ...}

  """
  @spec update_<%= schema.singular %>(t(), attrs()) :: {:ok, t()} | {:error, term()}
  def update_<%= schema.singular %>(%<%= inspect schema.alias %>{} = <%= schema.singular %>, attrs) do
    raise "TODO"
  end

  @doc """
  Deletes a <%= schema.singular %>.

  ## Examples

      iex> delete_<%= schema.singular %>(<%= schema.singular %>)
      {:ok, %<%= inspect schema.alias %>{}}

      iex> delete_<%= schema.singular %>(<%= schema.singular %>)
      {:error, ...}

  """
  @spec delete_<%= schema.singular %>(t()) :: {:ok, t()} | {:error, term()}
  def delete_<%= schema.singular %>(%<%= inspect schema.alias %>{} = <%= schema.singular %>) do
    raise "TODO"
  end

  @doc """
  Returns a data structure for tracking <%= schema.singular %> changes.

  ## Examples

      iex> change_<%= schema.singular %>(<%= schema.singular %>)
      %Todo{...}

  """
  @spec change_<%= schema.singular %>(t(), attrs()) :: term()
  def change_<%= schema.singular %>(%<%= inspect schema.alias %>{} = <%= schema.singular %>, attrs \\ %{}) do
    raise "TODO"
  end
