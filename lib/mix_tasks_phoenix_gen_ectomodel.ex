defmodule Mix.Tasks.Phoenix.Gen.Ectomodel do
  use Mix.Task
  import Phoenix.Gen.Utils
  import Mix.Generator
  import Mix.Shell.IO, only: [info: 1, error: 1]

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

    timestamps = if switches[:timestamps], do: "timestamps"

    model_bindings = [
      module: IO.inspect(
        Module.concat(app_name_camel, Mix.Utils.camelize(model_name))),
      fields: fields |> parse_fields |> schema_fields,
      table_name: Inflex.pluralize(model_name),
      timestamps: timestamps
    ]

    model_path = Path.relative_to models_path, Mix.Project.app_path
    model_file = Path.join model_path, "#{model_name}.ex"
    create_file model_file, model_template(model_bindings)

    unless switches[:skip_migration] do
      repo = case switches[:repo] do
        nil -> []
        r   -> ["-r", r]
      end
      Mix.Task.run("ecto.gen.migration", [migration_name(model_name)] ++ repo)
      mig_bindings = Keyword.merge model_bindings, [
        fields: fields |> parse_fields |> migration_fields,
      ]
      #TODO make sure task was successful and we have the right file
      mig_path = Path.relative_to migrations_path, Mix.Project.app_path
      mig_file = Path.join mig_path, (mig_path |> File.ls! |> List.last)
      mig = File.read! mig_file
      mig = String.replace mig, ~r/def up do.*  end/s, migration_template(mig_bindings)
      File.write! mig_file, mig
      info "Run your migration with: mix ecto.migrate #{Enum.join repo, " "}"
      info "Warning: Migrations are poorly tested, please check before running!"
    end
  end

  defp parse_fields(fields) do
    for field <- fields, do: String.split(field, ":")
  end

  defp schema_fields(fields) do
     for [field, type] <- fields, do: "field :#{field}, :#{type}"
  end

  defp migration_fields(fields) do
     for [field, type] <- fields, do: "add :#{field}, :#{type}"
  end

  defp migration_name(model_name) do
    "create_#{Inflex.pluralize model_name}_table"
  end

  embed_template :migration, """
  def change do
      create table(:<%= @table_name %>) do
        <%= Enum.join @fields, "\n      " %>
        <%= @timestamps %>
      end
    end
  """
  embed_template :model, """
  defmodule <%= @module %> do
    use Ecto.Model

    schema "<%= @table_name %>" do
      <%= Enum.join @fields, "\n    " %>
      <%= @timestamps %>
    end

  end
  """

end
