defmodule Mix.Tasks.Phoenix.Gen.Scaffold do
  use Mix.Task
  import Phoenix.Gen.Utils

  @shortdoc "Generate a Controller/Model/View/Template scaffold"
  @moduledoc """
  Generates a Controller/Model/View/Template scaffold

      mix phoenix.gen.scaffold resource_name field_name:field_type --repo:repo_name

    ## Command line options

    ## Examples

      mix phoenix.gen.scaffold post title:string body:string --repo:MyApp.Repo
  """

  def run(opts) do
    {_switches, [controller_name | _fields], _files} = OptionParser.parse opts
    Mix.Tasks.Phoenix.Gen.Controller.run [controller_name, "--crud"]
    Mix.Tasks.Phoenix.Gen.Ectomodel.run opts
  end

end
