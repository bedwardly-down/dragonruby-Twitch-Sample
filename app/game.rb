class Game
  attr_gtk
  attr_accessor :twitch

  def defaults
    self.twitch ||= Twitch.new 3, "logs/messages.txt"
  end

  def tick
    defaults
    @twitch.tick @args
  end
end
