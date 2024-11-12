# frozen_string_literal: true

class RedisClient

  def initialize(port, *args)
    @client = RedisServer.new(port).start
  end

  def execute(*args)
    # puts(args)
    puts "PONG\r\n"
  end
end
