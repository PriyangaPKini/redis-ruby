require "socket"
require_relative "client"

class RedisServer
  def initialize(port)
    @port = port
  end

  def start
    # You can use print statements as follows for debugging, they'll be visible when running tests.
    puts("Logs from your program will appear here!")

    # Uncomment this block to pass the first stage
    server = TCPServer.new(@port)
    server.accept
  end
end

client = RedisClient.new(6379).start
client.execute(ARGV)
