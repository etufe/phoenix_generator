defmodule Phoenix.Gen.Utils do

  @doc "returns the enclosing app's name camel case"
  def app_name_camel() do
    Mix.Utils.camelize app_name
  end

  def app_name() do
    Atom.to_string Mix.Project.config()[:app]
  end

  def models_path do
    Path.join ~w|web models|
  end

  def migrations_path do
    Path.join ~w|priv repo migrations|
  end

  def views_path do
    Path.relative_to Path.join(~w|web views|), Mix.Project.app_path
  end

  def templates_path do
    Path.relative_to Path.join(~w|web templates|), Mix.Project.app_path
  end

  def controllers_path do
    Path.relative_to Path.join(~w|web controllers|), Mix.Project.app_path
  end
end
