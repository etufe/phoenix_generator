defmodule Mix.Tasks.Phoenix.Gen.Controller do
  use Mix.Task
  import Phoenix.Gen.Utils

  @shortdoc "Generate a controller for a Phoenix Application"
  @moduledoc """
  Generates a Controller

      mix phoenix.gen.controller controller_name action

    ## Command line options

      * `--crud` - adds index, show, new, edit, create, update and destroy actions
      * `--skip-view` - don't generate a view or any templates

    ## Examples

      mix phoenix.gen.controller post recent --crud
  """

  def run(opts) do
    {switches, [controller_name | actions], _files} = OptionParser.parse opts

    if Keyword.get switches, :crud do
      actions = actions ++ ~w[index show new edit create update destroy]
    end

    bindings = [
      app_name: app_name_camel,
      controller_name: Mix.Utils.camelize(controller_name),
      actions: actions
    ]

    # generate the controller file
    gen_file(
      ["controller.ex.eex"],
      ["controllers", "#{controller_name}_controller.ex"],
      bindings)

    unless Keyword.get switches, :skip_view do
      # generate the view file
      Mix.Tasks.Phoenix.Gen.View.run [controller_name]

      # generate a template for each action
      if Keyword.get switches, :crud do
        # do not generate templates for create, update or destroy
        # if they were added wih --crud
        actions = Enum.take actions, length(actions)-3
      end
      for action <- actions do
        Mix.Tasks.Phoenix.Gen.Template.run [controller_name, action]
      end
    end
  end

end
