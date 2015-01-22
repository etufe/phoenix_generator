defmodule Mix.Tasks.Phoenix.Gen.Ectomodel do
  use Mix.Task
  import Phoenix.Gen.Utils

  @shortdoc "Generate an Ecto Model for a Phoenix Application"

  @moduledoc """
  Generates an Ecto Model

      mix phoenix.gen.ectomodel model\_name field\_name:field\_type

    ## Command line options

      * `--timestamps` - adds created_at:datetime and updated_at:datetime fields
      * `--repo=RepoName` - creates a migration if you specify a repo

    ## Examples

      mix phoenix.gen.ectomodel user first_name:string age:integer --timestamps
  """

  def run(opts) do
    {switches, [model_name | fields], _files} = OptionParser.parse opts

    if Keyword.get switches, :timestamps do
      fields = fields ++ ["created_at:datetime", "updated_at:datetime"]
    end

    bindings = [
      app_name: app_name_camel,
      model_name_camel: Mix.Utils.camelize(model_name),
      model_name_under: model_name,
      fields: option_to_ecto_fields(fields)
    ]

    # generate the model file
    gen_file(
      ["ectomodel.ex.eex"],
      ["models", "#{model_name}.ex"],
      bindings)

    # generate the migration
    import Mix.Shell.IO, only: [info: 1, error: 1]
    case Keyword.get switches, :repo do
      nil ->
        info "Generate a migration with:"
        info "  mix ecto.gen.migration *your_repo_name* #{migration_name(model_name)}"
        info "UP:"
        info "#{migration_up(model_name, option_to_postgres_fields(fields))}"
        info ""
        info "DOWN:"
        info "#{migration_down(model_name)}"
      repo ->
        case generate_migration model_name, option_to_postgres_fields(fields), repo do
          {:error, :no_ecto} ->
            error "You specified a repo but don't have Ecto."
            error "Please include ecto in your project dependencies."
            error "https://github.com/elixir-lang/ecto"
          :ok ->
            info "Run your migration with: mix ecto.migrate #{repo}"
            info "Warning: Migrations are poorly tested, please check before running!"
        end
    end
  end

  # Takes ["first_name:string", "age:integer"...]
  # Returns [["first_name", "string"], ["age", "integer"]...]
  defp option_to_ecto_fields(fields) do
    fields = for field <- fields, do: String.split(field, ":")
    for [name | field] <- fields do
      [name] ++ case field do
        []         -> ["string"]
        "datetime" -> ["datetime, default: Ecto.DateTime.utc"]
        "date"     -> ["date, default: Ecto.Date.utc"]
        "time"     -> ["time, default: Ecto.Time.utc"]
        other      -> [other]
      end
    end
  end

  # Takes ["first_name:string", "age:integer"...]
  # Returns [["first_name", "text"], "age", "bigint"]...]
  defp option_to_postgres_fields(fields) do
    #TODO binary, uuid, array, decimal
    fields = for field <- fields, do: String.split(field, ":")
    for [name | field] <- fields do
      [name] ++ case field do
        []              -> ["text"]
        "integer"       -> ["bigint"]
        "float"         -> ["float8"]
        "boolean"       -> ["boolean"]
        "string"        -> ["text"]
        "datetime" <> _ -> ["timestamptz"]
        "date" <> _     -> ["date"]
        "time" <> _     -> ["timetz"]
        other           -> [other]
      end
    end
  end

  # takes [[field_name, postgres_type]...]
  # returns {:error, :no_ecto} if it can't find ecto
  # returns :ok otherwise
  defp generate_migration(model_name, fields, repo) do
    if Mix.Task.task? Mix.Tasks.Ecto.Gen.Migration do
      Mix.Task.run Ecto.Gen.Migration, [repo, migration_name(model_name)]
      #TODO make sure task was successful and we have the right file
      path = Path.join ~w|priv repo migrations|
      file = path |> File.ls! |> List.last
      up = migration_up model_name, fields
      down = migration_down model_name
      contents = File.read! Path.join [path, file]
      contents = Regex.replace ~r/up do\n/s,
                    contents,
                    Regex.escape("up do\n" <> pad_string(up, "    ") <> "\n")
      contents = Regex.replace ~r/down do\n/s,
                    contents,
                    Regex.escape("down do\n" <> pad_string(down, "    ") <> "\n")
      File.write! Path.join([path, file]), contents
      :ok
    else
      {:error, :no_ecto}
    end
  end

  defp migration_name(model_name) do
    "create_#{Inflex.pluralize model_name}_table"
  end

  # Takes a list of postgres fields
  # Returns text for migration up
  defp migration_up(model_name, fields) do
    "\"CREATE TABLE #{Inflex.pluralize model_name}( \\\n" <>
    "  id serial primary key \\\n" <>
    "#{migration_field_lines(fields)}" <>
    ")\""
  end

  # Returns text for migration down
  defp migration_down(model_name) do
    "\"DROP TABLE #{Inflex.pluralize model_name}\""
  end

  # takes [[field_name, postgres_type]...]
  # returns a string containing the text to insert into a migration
  defp migration_field_lines(fields) do
    for [name, field] <- fields, into: "" do
      "  #{name} #{field} \\\n"
    end
  end

end
