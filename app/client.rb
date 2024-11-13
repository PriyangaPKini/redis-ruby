require "socket"

# frozen_string_literal: true

class RedisClient

  attr_reader :client

  def initialize(port, *args)
    @client = RedisServer.new(port).start
  end

  def parse_commands
    command = []
    first_line = client.gets&.strip
    if first_line && first_line.start_with?('*')
      num_elements = first_line[1..].to_i

      num_elements.times do
        length_line = client.gets&.strip
        if length_line && length_line.start_with?('$')
          str_length = length_line[1..].to_i
          element = client.read(str_length)&.strip
          client.gets
          command << element.upcase
        else
          client.puts "-ERR protocol error"
          return nil
        end
      end
      return command
    else
      client.puts "-ERR unknown command format"
      return nil
    end
  end

  def execute
    loop do
      queries = parse_commands
      case queries
      when %w[COMMAND DOCS]
        client.puts "+OK\r\n"
      when ["PING"]
        client.puts("+PONG\r\n")
      else
        puts("Error in your query  #{ queries }")
        client.puts("-ERR unknown command #{ queries }\r\n")
      end
    end
  end
end
