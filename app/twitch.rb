class Twitch
  attr_accessor :socket, :logged_in, :ping, :timeout, :path, :parsed_chat, :max_messages_held, :max_pings

  def initialize timeout, path
    self.socket ||= Socket.new "irc.twitch.tv", "6667"
    self.logged_in ||= false
    self.ping ||= 0
    self.timeout ||= timeout
    self.path ||= path
    self.parsed_chat ||= [{}]
    self.max_messages_held ||= 25
    self.max_pings ||= 60
  end

  def tick args
    if @logged_in == false
      login
    end

    keep_alive args.state.tick_count if @logged_in == true
    parse_chat args
    print_chat args
  end

  def login
    @socket.send_message "PASS #{Config::PASS}\n"
    @socket.send_message "NICK #{Config::NICK}\n"
    @socket.send_message "sender #{Config::USER}\n"
    @socket.send_message "JOIN ##{Config::CHANNEL}\n"
    @logged_in = true
  end

  def keep_alive tick_count
    if tick_count % 60 == 0
      @ping += 1
      if @ping % @timeout == 0
        @socket.send_message "PING\n"
        @socket.receive_message @path
      end
    end
  end

  def parse_chat args
    # read chat from log and make it mostly useful
    contents = "#{$gtk.read_file(@path)}"
      .split("\n")
      .reject { |line|
        line.start_with?(":tmi.twitch.tv 00") ||
        line.start_with?(":tmi.twitch.tv 3") ||
        line.start_with?("PONG") ||
        line.start_with?("PING") ||
        line.include?("JOIN ##{Config::CHANNEL}") ||
        line.include?(":-") ||
        line.include?(":>") ||
        line.include?(":Welcome") ||
        line.include?("\x7f") ||
        line.include?("tv 353") ||
        line.include?("tv 366") 
      }

    contents.each do |i|
      # grab a message and its sender from chat and empty the file that contains Twitch messages
      if i.include?("PRIVMSG")
        i.strip
        sender = parse_sender i
        message = parse_message i
        @parsed_chat.push(
          {
            sender: sender,
            message: message
          }
        )
        clear_chat_log
      end
    end

    # keep parsed_chat from getting too large
    @parsed_chat.pop if @parsed_chat.count > @max_messages_held

    # empty chat file when max amount of pings are reached to keep from blowing up on system
    if @ping >= @max_pings
      clear_chat_log
      @ping = @ping % @timeout
    end
  end

  def parse_sender chat
    str = ""
    arr = "#{chat}"
      .split(' ')
    arr.each do |i|
      if i.include?("tmi")
        arr2 = i.strip
          .sub('!', ' ')
          .sub(':','')
          .split(' ')
        str = arr2.first
      end
    end
    return str
  end

  def parse_message chat
    str = ""
    arr = "#{chat}"
      .split(' ')
    arr.each do |i|
      if i.include?("tmi") == false
        arr2 = i.strip
          .sub(':','')
          .split(' ')
        str = arr2.last
      end
    end
    return str
  end

  def clear_chat_log
    $gtk.write_file(@path, "\n")
  end

  def print_chat args
    args.outputs.labels << {
      x: 50,
      y: 100,
      text: "#{@ping}: #{@parsed_chat.last(1)}",
      size_enum: 1
    }
  end
end
