require "socket"

# frozen_string_literal: true
module Redis
  class RedisClient

    attr_reader :port

    def initialize(port, *args)
      @port = port
    end

    def execute
      client = TCPSocket.new("127.0.0.1", port)
      puts "Connected to server on port #{port}"
      client.puts("*1\r\n$4\r\nPING\r\n")
      while line = client.gets do
        puts line
        break if line.length
        client.puts(line)
        puts "Server response: #{line}"
      end
      client.close
    rescue => e
      puts "Connection encountered an error: #{e.message}"
    end
  end
end

client = Redis::RedisClient.new(6380)
client.execute
