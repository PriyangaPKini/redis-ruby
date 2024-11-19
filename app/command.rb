require_relative 'rdb_parser'

module Redis
  module Core
    module Command
      def command
        Encode.encode_simple("OK")
      end

      def ping
        Encode.encode_simple("PONG")
      end

      def echo(arg)
        unless arg
          return Encode.encode_error("ERR wrong number of arguments for 'echo' command")
        end
        Encode.encode_bulk(arg)
      end

      def set(args)
        if args.length.odd?
          return Encode.encode_error("ERR wrong number of arguments for 'set' command")
        end

        key, value, px, milliseconds = args
        store[key] = value
        if px&.upcase == "PX"
          expiration[key] = Time.now + (milliseconds.to_i / 1000.0)
        end

        Encode.encode_simple("OK")
      end

      def get(key)
        unless store.key?(key)
          return Encode.encode_bulk(nil)
        end

        if expiration.key?(key) && Time.now > expiration[key]
          return Encode.encode_bulk(nil)
        end

        value = store[key]
        Encode.encode_bulk(value)
      end

      def config_get(args)
        allowed_configs = %w[dir dbfilename]
        result = []
        args.filter { |arg| allowed_configs.include?(arg) }
            .each do |arg|
          value = config.send(arg)
          result = result.push(arg, value)
        end
        Encode.encode_aggregate(result)
      end

      def config_command(args)
        case args.first.upcase
        when "GET"
          config_get(args[1..])
        else
          Encode.encode_error("ERR unknown command")
        end
      end

      def keys(pattern)
        file_path = [config.dir, config.dbfilename].join('/')
        keys = Redis::RdbParser.new(file_path).keys
        Encode.encode_aggregate(keys)
      end

    end
  end
end
