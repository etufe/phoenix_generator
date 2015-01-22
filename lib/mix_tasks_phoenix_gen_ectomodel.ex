defmodule Mix.Tasks.Phoenix.Gen.Ectomodel do
  use Mix.Task
  import Phoenix.Gen.Utils
  import Mix.Utils, only: [camelize: 1]

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
    model_name_camel = camelize model_name
    app_name_camel = camelize Atom.to_string(Mix.Project.config()[:app])

    if Keyword.get switches, :timestamps do
      fields = fields ++ ["created_at:datetime", "updated_at:datetime"]
    end

    fields = for field <- fields do
      case String.split(field, ":") do
        [name]             -> [name, "string"]
        [name, "datetime"] -> [name, "datetime, default: Ecto.DateTime.utc"]
        [name, "date"]     -> [name, "date, default: Ecto.Date.utc"]
        [name, "time"]     -> [name, "time, default: Ecto.Time.utc"]
        [name, type]       -> [name, type]
      end
    end

    bindings = [
      app_name: app_name_camel,
      model_name_camel: model_name_camel,
      model_name_under: model_name,
      fields: fields
    ]

    # generate the model file
    gen_file(
      ["ectomodel.ex.eex"],
      ["models", "#{model_name}.ex"],
      bindings)

    # generate the migration
    import Mix.Shell.IO, only: [info: 1, error: 1]
    import Inflex, only: [pluralize: 1]

    migration_up = "\"CREATE TABLE #{pluralize model_name}( \\\n"
    migration_up = migration_up <> "  id serial primary key \\\n"
    migration_up = migration_up <> for [name, type] <- fields, into: "" do
      #TODO binary, uuid, array, decimal
      "  #{name} " <> case type do
        "integer"       -> "bigint"
        "float"         -> "float8"
        "boolean"       -> "boolean"
        "string"        -> "text"
        "datetime" <> _ -> "timestamptz"
        "date" <> _     -> "date"
        "time" <> _     -> "timetz"
        other           -> other
      end <> ", \\\n"
    end
    migration_up = migration_up <> ")\""
    migration_down = "\"DROP TABLE #{model_name};\""
    migration_name = "create_#{pluralize model_name}_table"

    case Keyword.get switches, :repo do
      nil ->
        info """
        Generate a migration with:"
          mix ecto.gen.migration *your_repo_name* #{migration_name}"
        UP:
        #{migration_up}

        DOWN:
        migration_down
        """
      repo ->
        if Mix.Task.task? Mix.Tasks.Ecto.Gen.Migration do
          Mix.Task.run Ecto.Gen.Migration, [repo, migration_name]
          info "Warning: Migrations are poorly tested, please check before running!"
          info "Run your migration with: mix ecto.migrate #{repo}"
        else
          error "You specified a repo but don't have Ecto."
          error "Please include ecto in your project dependencies."
          error "https://github.com/elixir-lang/ecto"
        end
    end
  end
end
