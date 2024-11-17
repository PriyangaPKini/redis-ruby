require "socket"
require "rspec"

require_relative "../app/server"

RSpec.describe Redis::Server do
  let(:port) { 6379 }
  let(:server) { described_class.new(port) }
  let(:client) { instance_double("TCPSocket") }

  describe "#parse_query" do
    it "returns an error when line starts with anything other than '*'" do
      allow(client).to receive(:gets).and_return("#7\r\n", "UNKNOWN\r\n")
      expect(client).to receive(:puts).with("-ERR unknown command format\r\n")

      response = server.parse_query(client)
      expect(response).to be_nil
    end

    it "returns an error when length indicator does not start with '$'" do
      allow(client).to receive(:gets).and_return("*1\r\n", "*1\r\n", "PING\r\n")
      expect(client).to receive(:puts).with("-ERR protocol error\r\n")

      response = server.parse_query(client)
      expect(response).to be_nil
    end

    it "returns an error when specified length is zero" do
      allow(client).to receive(:gets).and_return("*1\r\n", "$0\r\n", "PING\r\n")
      expect(client).to receive(:puts).with("-ERR protocol error\r\n")

      response = server.parse_query(client)
      expect(response).to be_nil
    end

    it "returns an error when specified length mismatches the length of any of the array element" do
      allow(client).to receive(:gets).and_return("*1\r\n", "$5\r\n", "PING\r\n")
      expect(client).to receive(:puts).with("-ERR unknown command format\r\n")

      response = server.parse_query(client)
      expect(response).to be_nil

      allow(client).to receive(:gets).and_return("*1\r\n", "$3\r\n", "y\r\n")
      expect(client).to receive(:puts).with("-ERR unknown command format\r\n")

      response = server.parse_query(client)
      expect(response).to be_nil
    end

    it "returns an array of commands and arguments on successful parsing" do
      allow(client).to receive(:gets).and_return("*2\r\n", "$3\r\n", "GET\r\n", "$4\r\n", "test\r\n")
      result = server.parse_query(client)
      expect(result).to eq(%w[GET test])
    end
  end

  describe "#execute" do
    it "returns an error for unknown command" do
      expect(client).to receive(:puts).with("-ERR unknown command\r\n")
      response = server.execute(client, %w[UNKNOWN])
      expect(response).to be_nil
    end

    it "responds with +PONG for PING command" do
      expect(client).to receive(:puts).with("+PONG\r\n")
      server.execute(client, %w[PING])
    end

    it "responds with +OK for COMMAND DOCS" do
      expect(client).to receive(:puts).with("+OK\r\n")
      server.execute(client, %w[COMMAND DOCS])
    end

    it "echoes back the argument for ECHO" do
      expect(client).to receive(:puts).with("$5\r\nHello\r\n")
      server.execute(client, %w[ECHO Hello])
    end

    it "returns an error when no argument is provided for ECHO" do
      expect(client).to receive(:puts).with("-ERR wrong number of arguments for 'echo' command\r\n")
      server.execute(client, %w[ECHO])
    end

    it "sets a value to the given key using SET command" do
      expect(client).to receive(:puts).with("+OK\r\n")
      server.execute(client, %w[SET foo bar])
    end

    it "gets the value to the given key using GET command" do
      server.store["key"] = {"value": "value"}
      expect(client).to receive(:puts).with("$5\r\nvalue\r\n")
      server.execute(client, %w[GET key])
    end

    it "returns (nil) when given key is not present in redis" do
      expect(client).to receive(:puts).with("$-1\r\n")
      server.execute(client, %w[GET non_existing_key])
    end

    it "sets a value to the given key and set an expiry using SET command" do
      expect(client).to receive(:puts).with("+OK\r\n")
      server.execute(client, %w[SET foo bar px 2000])
    end

    it "gets the value to the given key using GET command only if the key is not expired" do
      server.store["key"] = {"value": "value", "expires_on": 2000}
      expect(client).to receive(:puts).with("$5\r\nvalue\r\n")
      server.execute(client, %w[GET key])
    end

    it "returns (nil) when the key has expired" do
      milliseconds = 2000
      seconds = milliseconds / 1000.0
      server.store["key"] = {"value": "value", "expires_on": Time.now + seconds}
      expect(client).to receive(:puts).with("$-1\r\n")
      sleep(seconds + 2)
      server.execute(client, %w[GET key])
    end
  end
end
