defmodule Mix.Tasks.Phoenix.Gen.Template do
  use Mix.Task
  import Phoenix.Gen.Utils

  @shortdoc "Generate a template for a Phoenix Application"
  @moduledoc """
  Generates a Template

      mix phoenix.gen.template controller_name action

    ## Command line options

    ## Examples

      mix phoenix.gen.template user recent
  """

  def run(opts) do
    {_switches, [controller_name | template_name], _files} = OptionParser.parse opts

    bindings = [
      controller_name: controller_name,
      template_name: template_name,
      template_path: Path.join(
        ["web", "templates", controller_name, "#{template_name}.html.eex}"])
    ]

    gen_file(
      ["action.html.eex.eex"],
      ["templates", controller_name, "#{template_name}.html.eex"],
      bindings)
  end

end
