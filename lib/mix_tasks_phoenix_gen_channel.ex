defmodule Mix.Tasks.Phoenix.Gen.Channel do
  use Mix.Task
  import Mix.Generator
  import Phoenix.Gen.Utils

  @shortdoc "Generate a channel for a Phoenix Application"
  @moduledoc """
  Generates a Channel

      mix phoenix.gen.channel name

    ## Command line options
      * `--skip-route` - don't add the route for the channel

    ## Examples

      mix phoenix.gen.channel chat
  """

  def run(opts) do
    {switches, [channel_name | _args], _files} = OptionParser.parse opts
    bindings = [
      app_name: app_name_camel,
      module_name: Mix.Utils.camelize(channel_name)<>"Channel",
      channel_name: channel_name
    ]
    channel_file = Path.join channels_path, "#{channel_name}_channel.ex"
    create_file channel_file, channel_template(bindings)

    unless switches[:skip_route] do
      route_file = Path.join ~w|web router.ex|
      contents = File.read! route_file
      [_ | captures] = Regex.run(~r/(.*defmodule.*)(\nend)/s, contents)
      contents = Enum.join captures, channel_route_template(bindings)
      File.write! route_file, contents
      Mix.Shell.IO.info "A route was added for this channel."
    end
  end

  embed_template :channel, """
  defmodule <%= @app_name %>.<%= @module_name %> do
    use Phoenix.Channel

    def join(topic, message, socket) do
      {:ok, socket}
    end

  end
  """

  embed_template :channel_route, """

    socket "/<%= @channel_name %>socket", <%= @app_name %> do
      channel "<%= @channel_name %>:*", <%= @module_name %>
    end
  """

end
