defmodule Phoenix.Gen.Utils do

  # generate a file applying bindings and write it to disk
  # src_path is relative to phoenix_generator
  # dst_path is relative to enclosing project root
  def gen_file(src_path, dst_path, bindings \\ []) do
    src_path = Path.join([
      Mix.Project.deps_path, "phoenix_generator", "templates"] ++ src_path)
    dst_path = Path.join([File.cwd!, "web"] ++ dst_path)

    rendered_file = EEx.eval_file src_path, bindings

    Mix.Generator.create_file(dst_path, rendered_file)
  end
end

defmodule Mix.Tasks.Phoenix.Gen.Controller do
  use Mix.Task
  import Phoenix.Gen.Utils
  import Mix.Utils, only: [camelize: 1]

  @shortdoc "Generate a controller for a Phoenix Application"

  def run(opts) do
    {switches, [controller_name | actions], _files} = OptionParser.parse opts
    controller_name_camel = camelize controller_name
    app_name_camel = camelize Atom.to_string(Mix.Project.config()[:app])

    if Keyword.get switches, :crud do
      actions = actions ++ ~w[index show new edit create update destroy]
    end

    bindings = [
      app_name: app_name_camel,
      controller_name: controller_name_camel,
      actions: actions
    ]

    # generate the controller file
    gen_file(
      ["controller.ex.eex"],
      ["controllers", "#{controller_name}_controller.ex"],
      bindings)

    # generate the view file
    gen_file(
      ["view.ex.eex"],
      ["views", "#{controller_name}_view.ex"],
      bindings)

    # generate a template for each action
    if Keyword.get switches, :crud do
      # do not generate templates for create, update or destroy
      # if they were added wih --crud
      actions = Enum.take actions, length(actions)-3
    end
    for action <- actions do
      bindings = bindings ++ [action_name: action,
                   template_path: Path.join(
                     ["web","templates",controller_name,"#{action}.html.eex"])]
      gen_file(
        ["action.html.eex.eex"],
        ["templates", controller_name, "#{action}.html.eex"],
        bindings)
    end
  end

end
