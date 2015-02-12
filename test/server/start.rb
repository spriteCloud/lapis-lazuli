require "webrick"

# Configure the Webserver
server = WEBrick::HTTPServer.new(
  :Port => 9090,
  :DocumentRoot => File.expand_path("../www", __FILE__),
  AccessLog: [],
);

# Start a new thread with the server so cucumber can continue
thread = Thread.new { server.start }

# If this file was executed manually, let's wait for input
if __FILE__ == $0
  puts "Press enter to shut down the server."
  gets
end
