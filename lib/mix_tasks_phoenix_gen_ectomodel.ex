defmodule Mix.Tasks.Phoenix.Gen.Ectomodel do
  use Mix.Task
  import Phoenix.Gen.Utils
  import Mix.Generator

  @shortdoc "Generate an Ecto Model for a Phoenix Application"

  @moduledoc """
  Generates an Ecto Model

      mix phoenix.gen.ectomodel model_name field_name:field_type

    ## Command line options

      * `--timestamps` - adds created_at and updated_at to the model
      * `--repo=RepoName` - the repo to generate a migration for (defaults to `YourApp.Repo`)
      * `--skip-migration` - do not generate migration

    ## Examples

      mix phoenix.gen.ectomodel user first_name:string age:integer --timestamps
  """
  def run(opts) do
    {switches, [model_name | fields], _files} = OptionParser.parse opts

    timestamps = if Keyword.get(switches, :timestamps), do: "timestamps()"

    model_bindings = [
      module: Module.concat(app_name_camel, Mix.Utils.camelize(model_name)),
      fields: fields |> parse_fields |> schema_fields,
      table_name: Inflex.pluralize(model_name),
      timestamps: timestamps
    ]

    model_path = Path.relative_to models_path, Mix.Project.app_path
    model_file = Path.join model_path, "#{model_name}.ex"
    create_file model_file, model_template(model_bindings)

    # generate the migration
    # import Mix.Shell.IO, only: [info: 1, error: 1]
    # case Keyword.get switches, :repo do
    #   nil ->
    #     info "Generate a migration with:"
    #     info "  mix ecto.gen.migration *your_repo_name* #{migration_name(model_name)}"
    #     info "UP:"
    #     info "#{migration_up(model_name, option_to_postgres_fields(fields))}"
    #     info ""
    #     info "DOWN:"
    #     info "#{migration_down(model_name)}"
    #   repo ->
    #     case generate_migration model_name, option_to_postgres_fields(fields), repo do
    #       {:error, :no_ecto} ->
    #         error "You specified a repo but don't have Ecto."
    #         error "Please include ecto in your project dependencies."
    #         error "https://github.com/elixir-lang/ecto"
    #       :ok ->
    #         info "Run your migration with: mix ecto.migrate #{repo}"
    #         info "Warning: Migrations are poorly tested, please check before running!"
    #     end
    # end
  end

  defp parse_fields(fields) do
    for field <- fields, do: String.split(field, ":")
  end

  defp schema_fields(fields) do
     for [field, type] <- fields, do: "field :#{field}, :#{type}"
  end

  defp ecto_fields(fields) do
     for [field, type] <- fields, do: "add :#{field}, :#{type}"
  end

  # Takes ["first_name:string", "age:integer"...]
  # Returns [["first_name", "string"], ["age", "integer"]...]
  defp option_to_ecto_fields(fields) do
    fields = for field <- fields, do: String.split(field, ":")
    for [name | field] <- fields do
      [name] ++ case field do
        []         -> ["string"]
        other      -> [other]
      end
    end
  end

  # takes [[field_name, postgres_type]...]
  # returns {:error, :no_ecto} if it can't find ecto
  # returns :ok otherwise
  defp generate_migration(model_name, fields, repo) do
    if Mix.Task.task? Mix.Tasks.Ecto.Gen.Migration do
      Mix.Tasks.Ecto.Gen.Migration.run [migration_name(model_name), "--repo", repo]
      #TODO make sure task was successful and we have the right file
      path     = Path.join ~w|priv repo migrations|
      path     = Path.join path, (path |> File.ls! |> List.last)
      up       = migration_up model_name, fields
      down     = migration_down model_name
      contents = File.read! path
      [_, top, mid, bot] = Regex.run ~r/(.*up do\n)(.*down do\n)(.*)/s, contents
      contents = top <> pad_string(up, "    ") <>
                 mid <> pad_string(down, "    ") <> bot
      File.write! path, contents
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
    ")\"\n"
  end

  # Returns text for migration down
  defp migration_down(model_name) do
    "\"DROP TABLE #{Inflex.pluralize model_name}\"\n"
  end

  # takes [[field_name, postgres_type]...]
  # returns a string containing the text to insert into a migration
  defp migration_field_lines(fields) do
    for [name, field] <- fields, into: "" do
      "  #{name} #{field} \\\n"
    end
  end

  embed_template :migration, """
    def change do
      <%= Enum.join @fields, "\n      " %>
      <%= @timestamps %>
    end
  """
  embed_template :model, """
  defmodule <%= @module %> do
    use Ecto.Model
    <% IO.inspect "*************" %>
    <% IO.inspect @fields %>

    schema "<%= @tabel_name %>" do
      <%= Enum.join @fields, "\n    " %>
      <%= @timestamps %>
    end

  end
  """

end
