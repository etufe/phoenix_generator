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
      * `--repo` - repo to use with crud (defaults to 'YourApp.Repo')
      * `--skip-view` - don't generate a view or any templates
      * `--skip-route` - don't add the route if --crud was specified

    ## Examples

      mix phoenix.gen.controller post recent --crud
  """

  def run(opts) do
    {switches, [resource_name | actions], _files} = OptionParser.parse opts

    bindings = [
      module: Module.concat(
        app_name_camel, Mix.Utils.camelize(resource_name<>"Controller")),
      actions: actions,
      resource_name: resource_name,
      crud: switches[:crud],
      repo: switches[:repo] || Module.concat(app_name_camel, "Repo"),
      model: Module.concat(app_name_camel, Mix.Utils.camelize(resource_name))
    ]
    file = Path.join controllers_path, resource_name<>"_controller.ex"
    create_file file, controller_template(bindings)

    # generate the view file
    unless Keyword.get switches, :skip_view do
      Mix.Tasks.Phoenix.Gen.View.run [resource_name]
      for action <- actions do
        Mix.Tasks.Phoenix.Gen.Template.run [resource_name, action]
      end
      if switches[:crud] do
        for action <- ~w|index show new edit _form _list| do
          Mix.Tasks.Phoenix.Gen.Template.run [resource_name, action, "--crud"]
        end
      end
    end

    if switches[:crud] && !switches[:skip_route] do
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
  <%= if @crud do %>
    @repo <%= inspect @repo %>
    @model <%= inspect @model %>
    @resource_path "<%= Inflex.pluralize @resource_name %>"

    def index(conn, _params) do
      render conn, :index, resources: @repo.all(@model)
    end

    def show(conn, params) do
      render conn, :show, resource: @repo.get(@model, params["id"])
    end

    def new(conn, _params) do
      render conn, :new, resource: @model.__struct__
    end

    def edit(conn, params) do
      render conn, :edit, resource: @repo.get(@model, params["id"])
    end

    def create(conn, params) do
      changeset = @model.changeset(@model.__struct__, params["resource"])
      if changeset.valid? do
        resource = @repo.insert(changeset)
        render conn, :index, resources: @repo.all(@model)
      else
        render conn, :new, resource: Map.merge(@model.__struct__, params["resource"])
      end
    end

    def update(conn, params) do
      changeset = @model.changeset(@repo.get(@model, params["id"]), params["resource"])
      if changeset.valid? do
        resource = @repo.update(changeset)
        render conn, :show, resource: resource
      else
        render conn, :new, resource: Map.merge(@repo.get(@model, params["id"]), params["resource"])
      end
    end

    def delete(conn, params) do
      resource = @repo.get(@model, params["id"])
      @repo.delete resource
      redirect conn, to: "/" <> @resource_path
    end
  <% end %>

  <%= for action <- @actions do %>
    def <%= action %>(conn, _params) do
      render conn, :<%= action %>
    end
  <% end %>
  end
  """

end
