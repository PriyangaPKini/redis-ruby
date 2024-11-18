# frozen_string_literal: true
require 'rspec'
require_relative '../app/encode'

RSpec.describe Encode do
  include Encode
  describe 'encode methods' do
    test_cases = [
      { method: :encode_simple, input: 'Hello', expected: "+Hello\r\n" },
      { method: :encode_error, input: 'ERR Error occurred', expected: "-ERR Error occurred\r\n" },
      { method: :encode_integer, input: "42", expected: ":42\r\n" },
      { method: :encode_bulk, input: 'Bulk message', expected: "$12\r\nBulk message\r\n" },
      { method: :encode_bulk, input: nil, expected: "$-1\r\n" },
      {
        method: :encode_aggregate,
        input: %w[Hello World],
        expected: "$2\r\n$5\r\nHello\r\n$5\r\nWorld\r\n"
      }
    ]

    test_cases.each do |test_case|
      it "correctly encodes using #{test_case[:method]} with input #{test_case[:input].inspect}" do
        result = send(test_case[:method], test_case[:input])
        expect(result).to eq(test_case[:expected])
      end
    end
  end
end
