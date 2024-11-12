require "socket"

class RedisServer
  def initialize(port)
    @port = port
  end

  def start
    # You can use print statements as follows for debugging, they'll be visible when running tests.
    puts("Logs from your program will appear here!")

    # Uncomment this block to pass the first stage
    server = TCPServer.new(@port)
    client = server.accept
    client.puts("+PONG\r\n\n")
  end
end

RedisServer.new(6379).start
