# frozen_string_literal: true
require 'rspec'
require_relative '../app/core'
require_relative '../app/server'
require 'timecop'

RSpec.describe Core do
  let(:port) { 6381 }
  let(:server) { Redis::Server.new(port) }

  describe '#simple methods' do
    [
      { method: :command, expected: "+OK\r\n" },
      { method: :ping, expected: "+PONG\r\n" },
    ].each do |test_case|
      it "#{test_case[:method]} always returns '#{test_case[:expected]}'" do
        result = server.send(test_case[:method])
        expect(result).to eq(test_case[:expected])
      end
    end
  end

  describe '#echo' do
    [
      { method: :echo, input: nil, expected: "-ERR wrong number of arguments for 'echo' command\r\n" },
      { method: :echo, input: 'Hello', expected: "$5\r\nHello\r\n" }
    ].each do |test_case|
      it "returns '#{test_case[:expected]}' given 'echo #{test_case[:input]}'" do
        result = server.send(test_case[:method], test_case[:input])
        expect(result).to eq(test_case[:expected])
      end
    end
  end

  describe '#set' do
    [
      {
        method: :set,
        input: %w[key value],
        expected: "+OK\r\n"
      },
      {
        method: :set,
        input: %w[key value PX 1000],
        expected: "+OK\r\n"
      },
      {
        method: :set,
        input: %w[key value PX],
        expected: "-ERR wrong number of arguments for 'set' command\r\n"
      }
    ].each do |test_case|
      it "returns '#{test_case[:expected]}' given 'set #{test_case[:input]}'" do
        result = server.send(test_case[:method], test_case[:input])
        expect(result).to eq(test_case[:expected])
      end
    end
  end

  describe "#get" do
    [
      { method: :get,
        input: 'key',
        expected: "$5\r\nvalue\r\n",
        setup: ->(server) { server.store['key'] = 'value' }
      },
      { method: :get,
        input: 'nonexistent',
        expected: "$-1\r\n"
      },
      { method: :get,
        input: 'key_with_expiry',
        expected: "$5\r\nvalue\r\n",
        setup: ->(server) do
          server.store['key_with_expiry'] = 'value'
          server.expiration['key_with_expiry'] = Time.now + 3
        end
      },
      { method: :get,
        input: 'expired_key',
        expected: "$-1\r\n",
        setup: ->(server) do
          server.store['expired_key'] = 'value'
          server.expiration['expired_key'] = Time.now + 1
        end
      }
    ].each do |test_case|
      it "returns '#{test_case[:expected]}' given 'get #{test_case[:input]}'" do
        current_time = Time.now
        Timecop.freeze(current_time) do
          test_case[:setup]&.call(server)
          Timecop.travel(current_time + 2) do
            result = server.send(test_case[:method], test_case[:input])
            expect(result).to eq(test_case[:expected])
          end
        end
      end
    end
  end

end
