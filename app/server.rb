require "socket"

module Redis
  class RedisServer

    attr_reader :port

    def initialize(port)
      @port = port
    end

    def start
      server = TCPServer.new("127.0.0.1", port)
      puts "Redis server running on port #{port}..."
      loop do
        client = server.accept
        Thread.new(client) do |conn|
          handle_client(conn)
        end
      end
    rescue => e
      puts "Server encountered an error: #{e.message}"
    end

    def parse_query(client)
      command = []
      first_line = client.gets&.strip
      if first_line && first_line.start_with?('*')
        num_elements = first_line[1..].to_i

        num_elements.times do
          line = client.gets&.strip
          if line && line.start_with?('$')
            line_length = line[1..].to_i
            element = client.read(line_length)&.strip
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
    def handle_client(client)
      while queries = parse_query(client)
        case queries
        when %w[COMMAND DOCS]
          client.puts "+OK\r\n"
        when ["PING"]
          client.puts("+PONG\r\n")
        else
          client.puts("-ERR unknown command #{ queries }\r\n")
        end
      end
    end
  end
end


server = Redis::RedisServer.new(6379)
server.start
