defmodule Mix.Tasks.Phoenix.Gen.Jumpstart do
  use Mix.Task
  import Phoenix.Gen.Utils

  @shortdoc "Generate a bunch of setup stuff"
  @moduledoc """
  Generates a repo and database config

    ## Command line options
    * `--repo=RepoName` - Generates a repo with given name. Default is *AppName*.Repo
    * `--postgres-url=postgres_url` - Overrides postgres setings.

    ## Examples

      mix phoenix.gen.jumpstart --repo=MyApp.Repo
      mix phoenix.gen.jumpstart --postgres-url=ecto://postgres:postgres@localhost/ecto_test
  """

  def run(opts) do
    {switches, _params, _files} = OptionParser.parse opts
    repo = case Keyword.get(switches, :repo) do
      nil   -> ["--repo", app_name_camel<>".Repo"]
      other -> ["--repo", other]
    end

    Mix.Tasks.Ecto.Gen.Repo.run(repo)

    # Add the repo worker to supervision tree
    p_path = Path.join ["lib", app_name<>".ex"]
    [_, p_top, p_bot] = Regex.run ~r/(.*children = \[\n)(.*)/s, File.read!(p_path)
    File.write! p_path, p_top<>"      worker(#{List.last repo}, [])\n"<>p_bot
    IO.puts "The worker has been added for you!"

    # override postgres settings if --postgres-url
    if postgres_url = Keyword.get(switches, :postgres_url) do
      c_path    = Path.join ~w|config config.exs|
      re        = Regex.compile! "(?:[a-zA-Z\":_ ,]*\n+){4}$" #last 4 lines
      [top | _] = Regex.split re, File.read!(c_path)
      File.write! c_path, top<>"  url: \""<>postgres_url<>"\"\n"
      IO.puts "Postgres settings modified. Check config/config.exs."
    end

    IO.puts "To create a db run: mix ecto.create"

  end

end
