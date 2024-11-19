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

    end
  end
end
