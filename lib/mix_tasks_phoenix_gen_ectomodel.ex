defmodule Mix.Tasks.Phoenix.Gen.Ectomodel do
  use Mix.Task
  import Phoenix.Gen.Utils
  import Mix.Utils, only: [camelize: 1]

  @shortdoc "Generate an Ecto Model for a Phoenix Application"

  def run(opts) do
    {switches, [model_name | fields], _files} = OptionParser.parse opts
    model_name_camel = camelize model_name
    app_name_camel = camelize Atom.to_string(Mix.Project.config()[:app])

    if Keyword.get switches, :timestamps do
      fields = fields ++ ["created_at:datetime", "updated_at:datetime"]
    end

    fields = for field <- fields do
      case String.split(field, ":") do
        [name]             -> [name, ""]
        [name, "datetime"] -> [name, "datetime, default: Ecto.DateTime.utc"]
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
  end
end
