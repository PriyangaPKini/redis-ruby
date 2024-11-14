require "socket"

module Redis
  class Server

    attr_reader :port, :store

    def initialize(port)
      @port = port
      @store = {}
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
      unless first_line&.start_with?('*')
        client.puts "-ERR unknown command format\r\n"
        return nil
      end

      array_length = first_line[1..].to_i

      array_length.times do
        length_indicator = client.gets&.strip
        puts(length_indicator)
        unless length_indicator&.start_with?('$')
          client.puts "-ERR protocol error\r\n"
          return nil
        end

        element_length = length_indicator[1..].to_i
        if element_length <= 0
          client.puts "-ERR protocol error\r\n"
          return nil
        end

        element = client.gets&.strip
        if element.nil? || element.length != element_length
          client.puts "-ERR unknown command format\r\n"
          return nil
        end

        query << element
      end

      query
    end

    def execute(client, queries)
      case queries.first.upcase
      when "GET"
        key = queries[1]
        if store.key?(key)
          value = store[key]
          client.puts "$#{value.length}\r\n#{value}\r\n"
        else
          client.puts "$-1\r\n"
        end
      when "SET"
        key, value = queries[1..]
        if key.nil? or value.nil?
          client.puts "-ERR wrong number of arguments for 'set' command\r\n"
        else
          store[key] = value
          client.puts "+OK\r\n"
        end

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


server = Redis::Server.new(6379)
server.start
