require "socket"
require "pry"
require_relative 'encode'

module Redis
  class Server
    include Encode

    attr_reader :port, :store, :expiration

    def initialize(port)
      @port = port
      @store = {}
      @expiration = {}
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
      unless first_line&.start_with?("*")
        client.puts encode_error("ERR unknown command format")
        return nil
      end

      array_length = first_line[1..].to_i

      array_length.times do
        length_indicator = client.gets&.strip
        unless length_indicator&.start_with?("$")
          client.puts encode_error("ERR protocol error")
          return nil
        end

        element_length = length_indicator[1..].to_i
        if element_length <= 0
          client.puts encode_error("ERR protocol error")
          return nil
        end

        element = client.gets&.strip
        if element.nil? || element.length != element_length
          client.puts encode_error("ERR unknown command format")
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

        unless store.key?(key)
          client.puts encode_bulk(nil)
          return nil
        end

        if expiration.key?(key) && Time.now > expiration[key]
          client.puts encode_bulk(nil)
          return nil
        end

        value = store[key]
        client.puts encode_bulk(value)

      when "SET"
        if queries[1..].length.odd?
          client.puts encode_error("ERR wrong number of arguments for 'set' command")
          return nil
        end

        key, value = queries[1..2]
        px, milliseconds = queries[3..4]

        store[key] = value
        if px&.upcase == "PX"
          expiration[key] = Time.now + (milliseconds.to_i / 1000.0)
        end
        client.puts encode_simple("OK")

      when "COMMAND"
        client.puts encode_simple("OK")

      when "ECHO"
        arg = queries[1]
        if arg
          client.puts encode_bulk(arg)
        else
          client.puts encode_error("ERR wrong number of arguments for 'echo' command")
        end

      when "PING"
        client.puts encode_simple("PONG")
      else
        client.puts encode_error("ERR unknown command")
      end
    end

    def handle_client(client)
      while (queries = parse_query(client))
        execute(client, queries)
      end
    end
  end
end
