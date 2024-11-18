require_relative 'encode'

module Core
  include Encode

  def command
    encode_simple("OK")
  end
  def ping
    encode_simple("PONG")
  end

  def echo(arg)
    unless arg
      return encode_error("ERR wrong number of arguments for 'echo' command")
    end
    encode_bulk(arg)
  end

  def set(args)
    if args.length.odd?
      return encode_error("ERR wrong number of arguments for 'set' command")
    end

    key, value = args[1..2]
    store[key] = value

    px, milliseconds = args[3..4]
    if px&.upcase == "PX"
      expiration[key] = Time.now + (milliseconds.to_i / 1000.0)
    end

    encode_simple("OK")
  end

  def get(key)
    unless store.key?(key)
      return encode_bulk(nil)
    end

    if expiration.key?(key) && Time.now > expiration[key]
      return encode_bulk(nil)
    end

    value = store[key]
    encode_bulk(value)
  end

end
