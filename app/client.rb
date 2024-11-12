# frozen_string_literal: true

class RedisClient

  def initialize(port, *args)
    @client = RedisServer.new(port).start
  end

  def execute(*args)
    args.each do |arg|
      puts "PONG\r\n"
    end
  end
end
