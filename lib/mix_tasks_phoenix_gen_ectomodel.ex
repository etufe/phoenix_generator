defmodule Mix.Tasks.Phoenix.Gen.Ectomodel do
  use Mix.Task
  import Phoenix.Gen.Utils
  import Mix.Utils, only: [camelize: 1]

  @shortdoc "Generate an Ecto Model for a Phoenix Application"

  def run(opts) do
    {_switches, [model_name | _actions], _files} = OptionParser.parse opts
    model_name_camel = camelize model_name
    app_name_camel = camelize Atom.to_string(Mix.Project.config()[:app])

    bindings = [
      app_name: app_name_camel,
      model_name: model_name_camel
    ]

    # generate the model file
    gen_file(
      ["ectomodel.ex.eex"],
      ["models", "#{model_name}.ex"],
      bindings)
  end
end
