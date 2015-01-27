defmodule Mix.Tasks.Phoenix.Gen.Scaffold do
  use Mix.Task
  import Phoenix.Gen.Utils

  @shortdoc "Generate a Controller/Model/View/Template scaffold"
  @moduledoc """
  Generates a Controller/Model/View/Template scaffold

      mix phoenix.gen.scaffold resource_name field_name:field_type

    ## Command line options
      * `--repo=RepoName` - the repo to generate a migration for (defaults to `YourApp.Repo`)

    ## Examples

      mix phoenix.gen.scaffold post title:string body:string --repo:MyApp.Repo
  """

  def run(opts) do
    {switches, [resource_name | _fields], _files} = OptionParser.parse opts
    repo = case switches[:repo] do
      nil -> []
      r   -> ["--repo", r]
    end
    Mix.Tasks.Phoenix.Gen.Controller.run [resource_name, "--crud"]++repo
    Mix.Tasks.Phoenix.Gen.Ectomodel.run opts
  end

end
