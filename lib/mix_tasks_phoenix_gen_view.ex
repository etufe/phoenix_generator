defmodule Mix.Tasks.Phoenix.Gen.View do
  use Mix.Task
  import Mix.Generator
  import Phoenix.Gen.Utils

  @shortdoc "Generate a View for a Phoenix Application"
  @moduledoc """
  Generates a View

      mix phoenix.gen.view view_name

    ## Command line options

    ## Examples

      mix phoenix.gen.view user
  """

  def run(opts) do
    {_switches, [view_name | _args], _files} = OptionParser.parse opts
    bindings = [
      module: IO.inspect(
        Module.concat(app_name_camel, Mix.Utils.camelize(view_name<>"View"))),
      view: IO.inspect(Module.concat(Mix.Utils.camelize(view_name), View))
    ]
    file = Path.join views_path, "#{view_name}.ex"
    create_file file, view_template(bindings)
  end

  embed_template :view, """
  defmodule <%= @module %> do
    use <%= @view %>
  end
  """

end
