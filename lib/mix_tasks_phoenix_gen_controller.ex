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
      * `--skip-route` - don't add the route for actions or --crud

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

    unless switches[:skip_route] do
      if switches[:crud] do
        add_resources_route resource_name
        Mix.Shell.IO.info "A route was added for this resource."
      end

      for action <- actions do
        add_action_route(resource_name, action)
        Mix.Shell.IO.info "A route was added for #{resource_name}/#{action}"
      end
    end

    # For some reason router changes don't trigger a recompile
    # so we must manually clean the projec
    Mix.Tasks.Clean.run []
  end


  defp add_action_route(resource_name, action) do
    bindings = [
      controller_path: resource_name,
      action_path: (if action == "index", do: "", else: "/"<>action ),
      action: action,
      controller_name: Mix.Utils.camelize(resource_name)<>"Controller"
    ]
    add_route action_route_template(bindings)
  end

  defp add_resources_route(resource_name) do
    bindings = [
      resources_name: Inflex.pluralize(resource_name),
      controller_name: Mix.Utils.camelize(resource_name)<>"Controller"
    ]
    add_route resources_route_template(bindings)
  end

  defp add_route(route) do
    file     = Path.join ~w|web router.ex|
    contents = File.read! file
    [_ | captures] = Regex.run(router_regex, contents)
    contents = Enum.join captures, route
    File.write! file, contents
  end


  defp router_regex do
    ~r/(.*pipe_through :browser(?(?!end).)*\n)(.*)/s
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

  embed_template :resources_route, """
      resources "/<%= @resources_name %>", <%= @controller_name %>
  """

  embed_template :action_route, """
      get "/<%= @controller_path %><%= @action_path %>", <%= @controller_name %>, :<%= @action %>
  """

end
