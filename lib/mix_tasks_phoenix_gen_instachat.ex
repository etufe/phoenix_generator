defmodule Mix.Tasks.Phoenix.Gen.Instachat do
  # This module is a copy paste of Gen.Channel with a few additions
  use Mix.Task
  import Mix.Generator
  import Phoenix.Gen.Utils

  @shortdoc "Generate an instant chatroom for a Phoenix Application"
  @moduledoc """
  Generates a zero configuration chat room

      mix phoenix.gen.instachat

    ## Command line options

    ## Examples

      mix phoenix.gen.instachat
  """

  def run(_opts) do
    channel_name = "instachat"
    bindings = [
      app_name: app_name_camel,
      module_name: Mix.Utils.camelize(channel_name)<>"Channel",
      channel_name: channel_name
    ]
    # Add the Channel
    channel_file = Path.join channels_path, "#{channel_name}_channel.ex"
    create_file channel_file, channel_template(bindings)

    # Add the Channel Route
    route_file = Path.join ~w|web router.ex|
    route_contents = File.read! route_file
    [_ | captures] = Regex.run(~r/(.*defmodule.*)(\nend)/s, route_contents)
    route_contents = Enum.join captures, channel_route_template(bindings)
    File.write! route_file, route_contents
    Mix.Shell.IO.info "A route was added for this channel."

    # Generate the Controller and Action
    Mix.Tasks.Phoenix.Gen.Controller.run ["instachat", "index"]

    # Overwrite the Template
    template_path = Path.join [templates_path, "instachat", "index.html.eex"]
    File.write! template_path, html_template([])

    # Add the Config
    config_path = Path.join ~w|config config.exs|
    File.write! config_path, config_template([]), [:append]
    Mix.Shell.IO.info "Your config/config.exs was edited."
    Mix.Shell.IO.info "An ets table will be started to manage nicknames.\n"

    Mix.Tasks.Clean.run []

    Mix.Shell.IO.info """
    A chat room has been generated.
    Run: mix phoenix.server
    Visit: http://localhost:4000/instachat
    """
  end

  embed_template :channel_route, """

    socket "/instachatsocket", <%= @app_name %> do
      channel "instachat:*", InstachatChannel
    end
  """

  embed_template :config, """
  # Start an ets table to manage chat nick names
  :ets.new(:instachat, [:named_table, :public, :set])
  """

  embed_template :channel, """
  defmodule <%= @app_name %>.<%= @module_name %> do
    use Phoenix.Channel

    @doc "Handles when a user first joins the channel."
    def join(topic, nick, socket) do
      case :ets.lookup(:instachat, nick) do
        [{^nick, _}] ->
          reply socket, "error", %{nickTaken: true}
          {:error, :nick_taken, socket}
        _            ->
          socket  = Phoenix.Socket.put_topic(socket, topic)
          socket  = Phoenix.Socket.assign(socket, :nick, nick)
          :ets.insert(:instachat, {nick, socket[:pid]})
          reply socket, topic, %{start: "Welcome to the chat!"}
      end
    end

    @doc "Handles a user sending a chat message"
    def handle_in(topic, %{"body" => body}, socket) do
      broadcast socket, topic,
        %{body: body, nick: socket.assigns[:nick], room: socket.assigns[:room]}
    end

    @doc "Handles a user joining a room"
    def handle_in(topic, %{"room" => room}, socket) do
      socket = Phoenix.Socket.assign(socket, :room, room)
      broadcast socket, topic, %{join: socket.assigns[:nick], room: room}
      reply socket, topic, %{entered: room}
    end

    @doc "Handles outgoing broadcasts of chat messages"
    def handle_out(topic, %{body: body, nick: nick, room: room}, socket) do
      cond do
        # don't send the message to people not in the room
        socket.assigns[:room] !== room -> {:ok, socket}
        # send it to everyone else
        true                           -> reply socket,
                                          topic, %{body: body, nick: nick}
      end
    end

    @doc "Handles outgoing broadcasts of room joins"
    def handle_out(topic, %{join: nick, room: room}, socket) do
      cond do
        # don't send the join message to people not in the room
        socket.assigns[:room] !== room  -> {:ok, socket}
        # don't send the join message to the person who joined
        socket.assigns[:nick]  == nick  -> {:ok, socket}
        # send it to everyone else
        true                            -> reply socket,
                                           topic, %{join: nick}
      end
    end

    @doc "Catchall for broadcasts, anything not handlede gets forwarded"
    def handle_out(topic, msg, socket) do
      reply socket, topic, msg
    end

    @doc "Remove nicknames when a user disconnects"
    def leave(_, socket) do
      :ets.delete(:instachat, socket.assigns[:nick])
      {:ok, socket}
    end
  end
  """


  embed_template :html, """
  <br>
  <div id="chat">
    <form id="room-form" class="form-inline">
      <div class="row">
        <div class="col-xs-1">
          <label for="room">Room</label>
        </div>
        <div class="col-xs-4">
          <input id="room" type="text" class="form-control" value="general">
        </div>
        <div class="col-xs-4">
          <button id="room-submit" type="submit" class="btn btn-default">Join</button>
        </div>
      </div>
    </form>
    <br>
    <div id="messages" style="height:300px; overflow-y:scroll" class="form-control" rows="15">
    </div>
    <br>
    <form id="message-form" class="form">
      <div class="row">
        <div class="col-xs-10">
          <input id="message" type="text" class="form-control">
        </div>
        <div class="col-xs-1">
          <button id="message-submit" type="submit" class="btn btn-primary">Send</button>
        </div>
      </div>
    </form>
  </div>
  <br>

  <script src="http://code.jquery.com/jquery-2.1.3.min.js"></script>
  <script src="/js/phoenix.js"></script>
  <script type="text/javascript">
  // Helper function to prompt a user for a nick name
  var get_nick = function(message){
    var n = ""
    while(!n){
      n = window.prompt(message).trim();
    }
    return n;
  }
  // Helper function to insert messages
  var append_message = function(msg){
    $("#messages").append("<p>"+msg+"</p>")
    $("#messages").scrollTop($("#messages")[0].scrollHeight)
  }
  // Global channel var used in UI event handlers
  var channel = undefined;
  // Global socket
  var socket = new Phoenix.Socket("/instachatsocket");
  // Channel callbacks
  var callback = function(chan) {
    // Set the global channel
    channel = chan;

    // Prompt for a new nick if we recieve an error
    channel.on("error", function(error){
      var nick = get_nick("Sorry that nick is taken. Please choose another.")
      channel.message = nick;
      socket.rejoin(channel);
    });

    // Event handlers for mesages from the socket
    channel.on("instachat:room", function(payload){
       for( var key in payload ) {
         switch(key){
           case "entered":
              append_message("You entered the room: "+payload.entered+".")
              break;
           case "body":
              append_message("<strong>"+payload.nick+"</strong>: "+payload.body);
              break;
           case "join":
              append_message(payload.join + " joined the chat.");
              break;
            case "start":
              append_message(payload.start);
              channel.send("instachat:room", {room: "general"});
              break;
          }
        }
    });
  };

  // UI events
  $("#message-form").submit(function(e){
    e.preventDefault();
    message = $("#message").val();
    $("#message").val("");
    channel.send("instachat:room", {body: message});
  })
  $("#room-form").submit(function(e){
    e.preventDefault();
    room = $("#room").val();
    channel.send("instachat:room", {room: room});
  })

  // Prompt for a nick
  var nick = get_nick("Please choose a nickname");
  // Join the socket
  socket.join("instachat:room", nick, callback);

  </script>
  """

end
