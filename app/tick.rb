$gtk.ffi_misc.gtk_dlopen("libsocket")
include FFI::SOCKET

$game = Game.new

def tick args
  $game.args = args
  $game.tick
end
