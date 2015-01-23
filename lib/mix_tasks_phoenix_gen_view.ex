defmodule Mix.Tasks.Phoenix.Gen.View do
  use Mix.Task
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
      app_name: app_name_camel,
      view_name: Mix.Utils.camelize(view_name),
    ]

    gen_file(
      ["view.ex.eex"],
      ["views", "#{view_name}_view.ex"],
      bindings)
  end

end
