require 'zlib'

module Redis
  class RdbParser
    attr_reader :filepath, :data

    def initialize(filepath)
      @filepath = filepath
      @data = parse(filepath)
    end

    def parse_string_encoding(type)
      case type
      when 0xC0
        1
      when 0xC1
        2
      when 0xC2
        4
      else
        raise "#{type} size indicates that the string is compressed with the LZF algorithm"
      end
    end

    def parse_size_encoding(file)

      first_byte = file.read(1)&.ord
      return nil unless first_byte

      type = (first_byte & 0b11000000) >> 6
      remaining_bits = first_byte & 0b00111111

      case type
      when 0b00
        remaining_bits
      when 0b01
        next_byte = file.read(1).ord
        next_14_bits = (remaining_bits << 8) | next_byte
        next_14_bits
      when 0b10
        next_four_bytes = file.read(4)
        next_four_bytes.unpack1('N')
      when 0b11
        parse_string_encoding(first_byte)
      else
        raise "Invalid length type: #{type}"
      end
    end

    def parse_string(file)
      length = parse_size_encoding(file)
      return nil unless length

      file.read(length)
    end

    # Helper to parse auxiliary fields
    def parse_auxiliary_field(file)
      key = parse_string(file)

      value = parse_string(file)

      { key: key, value: value }
    end

    def parse_key_value(file)
      expiry = nil
      key_type = file.read(1).ord

      value_type = if key_type == 0xFD
                     expiry = file.read(4).unpack1('N')
                     file.read(1).ord
                   elsif key_type == 0xFC
                     expiry = file.read(8).unpack1('Q>')
                     file.read(1).ord
                   end

      value_type = value_type || key_type
      key = parse_string(file)
      value = parse_encoded_value(file, value_type)

      { key: key, value: value, type: value_type, expiry: expiry }
    end

    def parse_encoded_value(file, value_type)
      case value_type
      when 0x00 # String
        parse_string(file)
      when 0x01 # List
        length = parse_size_encoding(file)
        Array.new(length) { parse_string(file) }
      when 0x02 # Set
        length = parse_size_encoding(file)
        Set.new(Array.new(length) { parse_string(file) })
      when 0x03 # Sorted Set
        length = parse_size_encoding(file)
        (1..length).map do
          member = parse_string(file)
          score = file.read(8).unpack1('G') # Double-precision score
          [member, score]
        end.to_h
      when 0x04 # Hash
        length = parse_size_encoding(file)
        (1..length).map do
          field = parse_string(file)
          value = parse_string(file)
          [field, value]
        end.to_h
      else
        raise "Unsupported value type: #{value_type}"
      end
    end

    def parse(file_path)
      File.open(file_path, 'rb') do |file|
        magic_string = file.read(5)
        version = file.read(4)
        raise 'Invalid RDB file' unless magic_string == 'REDIS'
        raise 'Invalid RDB file' unless version == '0011'

        keys_value_store = []
        auxiliary_fields = []

        keys_store_size = 0
        expire_store_size = 0

        while (byte = file.read(1))
          case byte.ord
          when 0xFF
            break
          when 0xFE
            database_number = parse_size_encoding(file)
          when 0xFA
            auxiliary_fields.push(parse_auxiliary_field(file))
          when 0xFB
            keys_store_size = file.read(1).ord
            expire_store_size = file.read(1).ord
          else
            file.seek(-1, IO::SEEK_CUR)
            keys_value_store.push(parse_key_value(file))
          end
        end

        checksum = file.read(8)

        {
          magic_string: magic_string,
          version: version,
          database_number: database_number,
          auxiliary_fields: auxiliary_fields,
          keys_store_size: keys_store_size,
          expire_store_size: expire_store_size,
          keys_value_store: keys_value_store,
          checksum: checksum
        }
      end
    end

    def keys
      data[:keys_value_store].map { |item| item[:key] }
    end
  end

end
