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
    loop do
      client = server.accept
      execute(client, *ARGV)
    end
  end

  def execute(*args)
    puts("here")

    args.each do |arg|
      puts(arg)
      client.puts("PONG\r\n")
      response = client.gets
      puts("Messages from client #{response}")
    end
  end
end


RedisServer.new(6279).start

