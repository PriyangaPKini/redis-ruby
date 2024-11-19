require "socket"
require "pry"
require_relative 'encode'
require_relative 'command'

module Redis
  class Server
    include Redis::Core::Command

    attr_reader :port, :host, :store, :expiration

    def initialize(host: '127.0.0.1', port: 6379)
      @port = port
      @host = host
      @store = {}
      @expiration = {}
    end

    def start
      server = TCPServer.new(host, port)
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
      unless first_line&.start_with?("*")
        client.puts Encode.encode_error("ERR unknown command format")
        return nil
      end

      array_length = first_line[1..].to_i

      array_length.times do
        length_indicator = client.gets&.strip
        unless length_indicator&.start_with?("$")
          client.puts Encode.encode_error("ERR protocol error")
          return nil
        end

        element_length = length_indicator[1..].to_i
        if element_length <= 0
          client.puts Encode.encode_error("ERR protocol error")
          return nil
        end

        element = client.gets&.strip
        if element.nil? || element.length != element_length
          client.puts Encode.encode_error("ERR unknown command format")
          return nil
        end

        query << element
      end

      query
    end

    def execute(queries)
      case queries.first.upcase
      when "GET"
        get(queries[1])

      when "SET"
        set(queries[1..])

      when "COMMAND"
        command

      when "ECHO"
        echo(queries[1])

      when "PING"
        ping

      else
        Encode.encode_error("ERR unknown command")
      end
    end

    def handle_client(client)
      while (queries = parse_query(client))
        client.puts execute(queries)
      end
    end
  end
end
