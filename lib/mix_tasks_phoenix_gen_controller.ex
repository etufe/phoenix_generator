defmodule Mix.Tasks.Phoenix.Gen.Controller do
  use Mix.Task
  import Mix.Generator
  import Phoenix.Gen.Utils

  @shortdoc "Generate a controller for a Phoenix Application"
  @moduledoc """
  Generates a Controller

      mix phoenix.gen.controller resource_name action

    ## Command line options

      * `--crud` - adds index, show, new, edit, create, update and delete actions
      * `--skip-view` - don't generate a view or any templates
      * '--skip-route' - don't add the route if --crud was specified

    ## Examples

      mix phoenix.gen.controller post recent --crud
  """

  def run(opts) do
    {switches, [resource_name | actions], _files} = OptionParser.parse opts

    if switches[:crud] do
      actions = actions ++ ~w|index show new edit create update delete|
    end

    bindings = [
      module: Module.concat(
        app_name_camel, Mix.Utils.camelize(resource_name<>"Controller")),
      actions: actions,
      resource_name: resource_name
    ]
    file = Path.join controllers_path, resource_name<>"_controller.ex"
    create_file file, controller_template(bindings)

    # generate the view file
    unless Keyword.get switches, :skip_view do
      Mix.Tasks.Phoenix.Gen.View.run [resource_name]
      # generate a template for each action but
      # do not generate templates for create, update or delete
      # if they were added wih --crud
      if switches[:crud], do: actions = Enum.take actions, length(actions)-3
      for action <- actions do
        Mix.Tasks.Phoenix.Gen.Template.run [resource_name, action]
      end
    end

    unless Keyword.get switches, :skip_route do
      add_resources_route resource_name
      Mix.Shell.IO.info "A route was added for this resource."
    end
  end


  defp add_resources_route(resource_name) do
    file = Path.join ~w|web router.ex|
    contents = File.read! file
    [_ | captures] = Regex.run(~r/(.*pipe_through :browser(?(?!end).)*\n)(.*)/s,
                               contents)
    contents = Enum.join captures, resources_route(resource_name)
    File.write! file, contents
  end

  defp resources_route(resource_name) do
    "    resources \"/#{Inflex.pluralize resource_name}\", " <>
    "#{Mix.Utils.camelize resource_name}Controller\n"
  end

  embed_template :controller, """
  defmodule <%= inspect @module %> do
    use Phoenix.Controller

    plug :action

  <%= for action <- @actions do %>
    def <%= action %>(conn, _params) do
      render conn, :<%= action %>
    end
  <% end %>
  end
  """

end
