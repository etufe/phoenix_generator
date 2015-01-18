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
