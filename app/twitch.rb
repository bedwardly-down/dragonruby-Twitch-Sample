class Twitch
  attr_accessor :socket, :logged_in, :ping, :timeout

  def initialize timeout
    self.socket ||= Socket.new "irc.twitch.tv", "6667"
    self.logged_in ||= false
    self.ping ||= 0
    self.timeout ||= timeout
  end

  def tick args
    if @logged_in == false
      login
    end

    keep_alive args.state.tick_count if @logged_in == true
    parse_chat args
  end

  def login
    @socket.send_message "PASS #{Config::PASS}\n"
    @socket.send_message "NICK #{Config::NICK}\n"
    @socket.send_message "USER #{Config::USER}\n"
    @socket.send_message "JOIN ##{Config::CHANNEL}\n"
    @logged_in = true
  end

  def keep_alive tick_count
    if tick_count % 60 == 0
      @ping += 1
      if @ping == @timeout
        @socket.send_message "PING\n"
        @socket.receive_message
        @ping = 0
      end
    end
  end

  def parse_chat args
    contents = $gtk.read_file("logs/messages.txt")
    args.outputs.labels << {
      x: 50,
      y: 100,
      text: "#{contents}\n",
      size_enum: 1
    }
  end
end
