# frozen_string_literal: true

module Encode
    def encode_simple(message)
      "+#{message}\r\n"
    end

    def encode_error(message)
      "-#{message}\r\n"
    end

    def encode_integer(message)
      ":#{message}\r\n"
    end

    def encode_bulk(message)
      return "$-1\r\n" if message.nil?

      length = message.length
      "$#{length}\r\n#{message}\r\n"
    end

    def encode_aggregate(message)
      length = message.length
      result = "$#{length}\r\n"
      message.each { |element| result += encode_bulk(element) }
      result
    end
end
