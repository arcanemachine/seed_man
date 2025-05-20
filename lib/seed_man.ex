defmodule SeedMan do
  @moduledoc "Save and load seed data to/from the database as compressed backup files."

  import Ecto.Query
  require Logger

  @doc """
  Dump table data for a given `schema_module` to a file in the seeds directory
  (e.g. `priv/repo/seeds`).

  This function is intended to make it easy to save seed data from an external database so that it
  can be used to seed local tables during development.

  > #### Tip {: .tip}
  >
  > Before calling this function, ensure that you have started the server with the application
  > configured to use the correct database you want to save the seed data from.

  ## Options

  - `:comment` - Add a comment to the top of the seed file (e.g. "Hello world!").

  - `:seed_data` - Specify custom data to dump to the seed file. If this value is not specified,
  then the full contents of the given schema/table will be dumped as seed data.

  ## Examples

  Dump the contents of a given schema/table to a seed file:

      iex> SeedMan.dump_schema_to_seed_file(YourProject.Repo, YourProject.Persons.Person)
      :ok

  Dump the contents of a given schema/table to a seed file with a custom comment embedded in the
  seed file:

      iex> SeedMan.dump_schema_to_seed_file(
      ...>   YourProject.Repo,
      ...>   YourProject.Persons.Person,
      ...>   comment: "For anyone who reads this, X was done because of Y."
      ...> )
      :ok

  Dump the contents of the current table to a seed file using custom `:seed_data`:

      iex> SeedMan.dump_schema_to_seed_file(
      ...>   YourProject.Repo,
      ...>   YourProject.Persons.Person,
      ...>   seed_data: [%{...}, %{...}],
      ...> )
      :ok
  """
  @spec dump_schema_to_seed_file(module(), module(), keyword()) :: :ok
  def dump_schema_to_seed_file(repo_module, schema_module, opts \\ []) do
    comment =
      if Keyword.get(opts, :comment) do
        opts[:comment]
        |> String.split("\n")
        # Convert to commented lines
        |> Enum.map(&"# #{&1}\n")
        # Remove blank line generated when using multi-line strings
        |> Enum.reject(&String.ends_with?(&1, "# #{&1}\n"))
        |> Enum.join()
      else
        ""
      end

    seed_data = Keyword.get(opts, :seed_data, dump_table_as_seed_data(repo_module, schema_module))

    table_name = schema_module.__schema__(:source)
    seed_file_path = get_seed_file_path(repo_module, table_name)

    Logger.info(~s(Dumping seed data for the table "#{table_name}" to "#{seed_file_path}"...))

    compressed_seed_data = (comment <> inspect(seed_data, limit: :infinity)) |> :zlib.gzip()

    # Ensure the custom seeds directory exists
    seed_files_directory_path = build_seed_files_directory_path(repo_module)
    File.mkdir_p(seed_files_directory_path)

    File.write!(seed_file_path, compressed_seed_data)

    :ok
  end

  @doc false
  def eval_seed_data_from_seed_file(repo_module, schema_module) do
    read_seed_file(repo_module, schema_module)
    |> Code.eval_string()
    |> elem(0)
  end

  @doc """
  Load table data for a `schema_module` into a repo by its `repo_module` from an existing seed
  data file (to save seed data, see `dump_schema_to_seed_file/3`).

  This function is intended to make it easy to load seed data that was previously saved to the
  seed files directory path (e.g. `priv/repo/seeds`) to make it easier to work with a local
  database during development.

  > #### Tip {: .tip}
  >
  > Before calling this function, ensure that you have started the server with the application
  > configured to use the correct database you want to load the seed data into.

  ## Examples

      iex> SeedMan.load_schema_from_seed_file(YourProject.Repo, YourProject.Persons.Person)
      :ok

  ## Options

  - `:insert_all_function_atom` - The 2-arity repo function to use (default: `:insert_all`)

  - `:insert_all_opts` - The opts to pass to the `:insert_all` function. Useful if custom options
  must be passed when calling the function, e.g. placeholders. (default: `[]`)
  """
  @spec load_schema_from_seed_file(module(), module()) :: :ok
  def load_schema_from_seed_file(repo_module, schema_module, opts \\ []) do
    insert_all_function_atom = Keyword.get(opts, :insert_all_function_atom, :insert_all)
    insert_all_opts = Keyword.get(opts, :insert_all_opts, [])

    table_name = schema_module.__schema__(:source)

    seed_file_path = get_seed_file_path(repo_module, table_name)
    seed_data = eval_seed_data_from_seed_file(repo_module, schema_module)

    Logger.info(~s(Loading seed data for the table "#{table_name}" from "#{seed_file_path}"...))
    repo_module.insert_all(schema_module, seed_data)

    apply(repo_module, insert_all_function_atom, [schema_module, insert_all_opts])

    :ok
  end

  @doc """
  Read seed data for a given schema module.

  This function is used to read the seed data before loading it into the database. It is also
  useful for viewing the contents (including any comments) of seed files.

  ## Options

  - `:comment_only?` - If `true`, then just return the comment embedded in the seed file.
  """
  def read_seed_file(repo_module, schema_module, opts \\ []) do
    comment_only? = Keyword.get(opts, :comment_only?, false)

    table_name = schema_module.__schema__(:source)
    seed_file_path = get_seed_file_path(repo_module, table_name)
    seed_file_contents = File.read!(seed_file_path) |> :zlib.gunzip()

    if comment_only? do
      seed_file_contents
      |> String.split("\n")
      |> Enum.filter(&String.starts_with?(&1, "# "))
      |> Enum.join("\n")
      |> then(fn
        "" -> nil
        comment -> comment
      end)
    else
      seed_file_contents
    end
  end

  defp build_seed_files_directory_path(repo_module) do
    repo_directory_name = repo_module |> Macro.underscore() |> String.split("/") |> List.first()

    "priv/#{repo_directory_name}/seeds"
  end

  defp dump_table_as_seed_data(repo_module, schema_module) do
    # Build seed data from current table contents
    keys_to_drop =
      [:__meta__] ++
        schema_module.__schema__(:associations) ++ schema_module.__schema__(:autogenerate_fields)

    repo_module.all(
      from(_sm in schema_module,
        # Order by primary key to ensure that the query results are consistent
        order_by: ^List.first(schema_module.__schema__(:primary_key))
      )
    )
    |> Enum.map(&Map.from_struct/1)
    |> Enum.map(&Map.drop(&1, keys_to_drop))
  end

  defp get_seed_file_path(repo_module, table_name) do
    # TODO: Get the OTP application name and seed file path directly, not by parsing `repo_module`
    otp_application_name =
      repo_module |> Macro.underscore() |> String.split("/") |> List.first() |> String.to_atom()

    seed_files_directory_path =
      Application.app_dir(
        otp_application_name,
        build_seed_files_directory_path(repo_module)
      )

    if not File.exists?(seed_files_directory_path) do
      raise """
      the seed files directory does not exist, create it and try again: \
      `#{seed_files_directory_path}`\
      """
    end

    Path.join(seed_files_directory_path, "#{table_name}.exs.gz")
  end
end
