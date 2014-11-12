require "webrick"

# Configure the Webserver
server = WEBrick::HTTPServer.new(
  :Port => 9090,
  :DocumentRoot => File.expand_path("../www", __FILE__),
  Logger: WEBrick::Log.new("/dev/null"),
  AccessLog: [],
);

# On interupt shutdown the server
trap('INT') {
  server.shutdown
};

# Start a new thread with the server so cucumber can continue
thread = Thread.new { server.start }
