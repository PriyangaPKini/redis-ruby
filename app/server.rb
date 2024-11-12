require "socket"
require_relative "client"

class RedisServer
  def initialize(port)
    @port = port
  end

  def start
    # Uncomment this block to pass the first stage
    server = TCPServer.new("127.0.0.1", @port)
    client = server.accept
    puts "Redis server running on port #{@port}..."
    client
  end
end


client = RedisClient.new(6380)
client.execute
