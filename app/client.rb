# frozen_string_literal: true

class RedisClient

  def initialize(port, *args)
    @client = RedisServer.new(port).start
  end

  def execute(*args)
    puts("here")

    args.each do |arg|
      puts(arg)
      @client.puts("PONG\r\n")
      response = @client.gets
      puts("Messages from client #{response}")
    end
  end
end
