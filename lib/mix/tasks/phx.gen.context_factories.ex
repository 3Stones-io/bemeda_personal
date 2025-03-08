defmodule Mix.Tasks.Phx.Gen.ContextFactories do
  @shortdoc "Generates factory functions for contexts using ExMachina"

  @moduledoc """
  Generates factory functions for contexts using ExMachina.

      $ mix phx.gen.context_factories Accounts User users name:string age:integer

  The first argument is the context module followed by the schema module
  and its plural name (used as the schema table name).

  The generator will create a factory for the specified schema. If a factory.ex
  file already exists, it will append the factory function to it. Otherwise,
  it will create a new factory module.

  ## Options

  Same options supported by `phx.gen.context`.
  """

  use Mix.Task

  alias Mix.Phoenix.{Context, Schema}
  alias Mix.Tasks.Phx.Gen

  @switches [
    binary_id: :boolean,
    table: :string,
    web: :string,
    schema: :boolean,
    context: :boolean,
    context_app: :string
  ]

  @default_opts [schema: true, context: true]

  @doc false
  def run(args) do
    if Mix.Project.umbrella?() do
      Mix.raise(
        "mix phx.gen.context_factories must be invoked from within your *_web application root directory"
      )
    end

    {context, schema} = build(args)
    binding = [
      context: context,
      schema: schema,
      app_module: context.base_module,
      aliases: get_aliases(context, schema),
      factory_defaults: generate_factory_defaults(schema)
    ]
    paths = Mix.Phoenix.generator_paths()

    # Generate factory code
    ensure_factory_file_exists(paths, binding)
    inject_factory_function(schema, paths, binding)

    print_shell_instructions()
  end

  # Generate factory default values for the schema fields based on their types
  defp generate_factory_defaults(schema) do
    schema.attrs
    |> Enum.map(fn {field, type} ->
      field_name = to_string(field)
      {field, type, generate_default_for_type(type, field_name)}
    end)
  end

  # Generate default values for each field type
  defp generate_default_for_type(type, field_name) do
    case type do
      :integer -> "sequence(:#{field_name}, &(&1))"
      :float -> "sequence(:#{field_name}, &(Float.round(&1 * 1.0, 2)))"
      :boolean -> "sequence(:#{field_name}, &(rem(&1, 2) == 0))"
      :map -> "%{}"
      :decimal -> "Decimal.new(\"0.00\")"
      :date -> "~D[2022-01-01]"
      :time -> "~T[12:00:00]"
      :time_usec -> "~T[12:00:00.000000]"
      :uuid -> "Ecto.UUID.generate()"
      :binary_id -> "Ecto.UUID.generate()"
      :naive_datetime -> "~N[2022-01-01 12:00:00]"
      :naive_datetime_usec -> "~N[2022-01-01 12:00:00.000000]"
      :utc_datetime -> "DateTime.from_naive!(~N[2022-01-01 12:00:00], \"Etc/UTC\")"
      :utc_datetime_usec -> "DateTime.from_naive!(~N[2022-01-01 12:00:00.000000], \"Etc/UTC\")"
      :references -> "nil"
      :array -> "[]"
      :string -> generate_string_default(field_name)
      _ -> "nil"
    end
  end

  # Generate defaults for string fields based on field name
  defp generate_string_default(field_name) do
    case field_name do
      "email" -> "sequence(:email, &\"email-\#{&1}@example.com\")"
      "username" -> "sequence(:username, &\"user\#{&1}\")"
      "password" -> "\"password\""
      "title" -> "sequence(:title, &\"Title \#{&1}\")"
      "name" -> "sequence(:name, &\"Name \#{&1}\")"
      "slug" -> "sequence(:slug, &\"slug-\#{&1}\")"
      "url" -> "sequence(:url, &\"https://example.com/\#{&1}\")"
      "phone" -> "sequence(:phone, &\"123-456-78\#{rem(&1, 100)}\")"
      "address" -> "\"123 Main St\""
      "description" -> "\"A description\""
      "status" -> "\"active\""
      "type" -> "\"default\""
      _ -> "sequence(:#{field_name}, &\"#{field_name}-\#{&1}\")"
    end
  end

  defp build(args, help \\ __MODULE__) do
    {opts, parsed, _} = parse_opts(args)
    [context_name, schema_name, plural | schema_args] = validate_args!(parsed, help)
    schema_module = inspect(Module.concat(context_name, schema_name))
    schema = Gen.Schema.build([schema_module, plural | schema_args], opts, help)
    context = Context.new(context_name, schema, opts)
    {context, schema}
  end

  defp parse_opts(args) do
    {opts, parsed, invalid} = OptionParser.parse(args, switches: @switches)

    merged_opts =
      @default_opts
      |> Keyword.merge(opts)
      |> put_context_app(opts[:context_app])

    {merged_opts, parsed, invalid}
  end

  defp put_context_app(opts, nil), do: opts

  defp put_context_app(opts, string) do
    Keyword.put(opts, :context_app, String.to_atom(string))
  end

  defp get_aliases(context, schema) do
    schema_module = Module.concat([context.base_module, context.name, schema.singular |> Phoenix.Naming.camelize()])
    [inspect(schema_module)]
  end

  defp ensure_factory_file_exists(paths, binding) do
    factory_file = factory_file_path()

    unless File.exists?(factory_file) do
      Mix.Generator.create_file(
        factory_file,
        Mix.Phoenix.eval_from(paths, "priv/templates/phx.gen.context/factory.ex", binding)
      )
    end
  end

  defp inject_factory_function(schema, paths, binding) do
    factory_file = factory_file_path()

    unless factory_function_exists?(factory_file, schema) do
      Mix.shell().info([:green, "* injecting ", :reset, Path.relative_to_cwd(factory_file)])

      factory_function =
        Mix.Phoenix.eval_from(paths, "priv/templates/phx.gen.context/factories_function.ex", binding)

      inject_before_final_end(factory_function, factory_file)
    end
  end

  defp factory_file_path do
    Path.join(["test", "support", "factory.ex"])
  end

  defp factory_function_exists?(factory_file, schema) do
    if File.exists?(factory_file) do
      file_content = File.read!(factory_file)
      function_name = "#{schema.singular}_factory"
      String.contains?(file_content, "def #{function_name}")
    else
      false
    end
  end

  defp inject_before_final_end(content_to_inject, file_path) do
    file = File.read!(file_path)

    if String.contains?(file, content_to_inject) do
      :ok
    else
      file
      |> String.trim_trailing()
      |> String.trim_trailing("end")
      |> Kernel.<>(content_to_inject)
      |> Kernel.<>("end\n")
      |> write_file(file_path)
    end
  end

  defp write_file(content, file) do
    File.write!(file, content)
  end

  defp print_shell_instructions do
    Mix.shell().info("""

    Remember to add ExMachina as a dependency in mix.exs:

        def deps do
          [
            {:ex_machina, "~> 2.8.0", only: :test}
          ]
        end

    And to start the application in test/test_helper.exs:

        {:ok, _} = Application.ensure_all_started(:ex_machina)
    """)
  end

  defp validate_args!([context, schema, _plural | _] = args, help) do
    cond do
      not Context.valid?(context) ->
        help.raise_with_help(
          "Expected the context, #{inspect(context)}, to be a valid module name"
        )

      not Schema.valid?(schema) ->
        help.raise_with_help("Expected the schema, #{inspect(schema)}, to be a valid module name")

      context == schema ->
        help.raise_with_help("The context and schema should have different names")

      context == Mix.Phoenix.base() ->
        help.raise_with_help(
          "Cannot generate context #{context} because it has the same name as the application"
        )

      schema == Mix.Phoenix.base() ->
        help.raise_with_help(
          "Cannot generate schema #{schema} because it has the same name as the application"
        )

      true ->
        args
    end
  end

  defp validate_args!(_, help) do
    help.raise_with_help("Invalid arguments")
  end

  @doc false
  def raise_with_help(msg) do
    Mix.raise("""
    #{msg}

    mix phx.gen.context_factories expects a context module name, followed by singular and plural names
    of the generated resource, ending with any number of attributes.
    For example:

        mix phx.gen.context_factories Accounts User users name:string
    """)
  end
end
