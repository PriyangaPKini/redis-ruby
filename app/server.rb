require "socket"
require "pry"
require_relative 'encode'
require_relative 'command'
require_relative 'core'

module Redis
  class Server
    include Redis::Core::Command

    attr_reader :store, :expiration, :config

    def initialize(port:nil, host:nil, dir:nil, dbfilename:nil)
      Redis.configure do |config|
        config.port = port if port
        config.host = host if host
        config.dir = dir if dir
        config.dbfilename = dbfilename if dbfilename
      end
      @config = Redis.configuration
      @store = {}
      @expiration = {}
    end

    def start
      server = TCPServer.new(config.host, config.port)
      puts "Redis server running on port #{config.port}..."
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
      when "KEYS"
        keys(queries[1..])
      when "CONFIG"
        config_command(queries[1..])
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
