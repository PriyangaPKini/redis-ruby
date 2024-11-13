require "socket"

module Redis
  class Server

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
      query = []
      first_line = client.gets&.strip
      if first_line && first_line.start_with?('*')
        num_elements = first_line[1..].to_i

        num_elements.times do
          line = client.gets&.strip
          if line && line.start_with?('$')
            line_length = line[1..].to_i
            element = client.read(line_length)&.strip
            client.gets
            query << element
          else
            client.puts "-ERR protocol error\r\n"
            return nil
          end
        end
        return query
      else
        client.puts "-ERR unknown command format\r\n"
        return nil
      end
    end

    def execute(client, queries)

      case queries.first.upcase
      when "COMMAND"
        client.puts "+OK\r\n"
      when "ECHO"
        arg = queries[1]
        if arg
          client.puts "$#{arg.length}\r\n#{arg}\r\n"
        else
          client.puts "-ERR wrong number of arguments for 'echo' command\r\n"
        end
      when "PING"
        client.puts("+PONG\r\n")
      else
        client.puts("-ERR unknown command\r\n")
      end
    end

    def handle_client(client)
      while queries = parse_query(client)
        execute(client, queries)
      end
    end
  end
end


server = Redis::Server.new(6380)
server.start
