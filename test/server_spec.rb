require 'socket'

require_relative '../app/server'

RSpec.describe Redis::Server do
  let(:port) { 6381 }
  let(:server) { Redis::Server.new(port) }

  before(:all) do
    @server_thread = Thread.new { Redis::Server.new(6381).start }
    sleep 0.5
  end

  after(:all) do
    Thread.kill(@server_thread)
  end

  def send_command(command)
    client = TCPSocket.new("127.0.0.1", port)
    client.puts command
    response = client.readpartial(1024)
    client.close
    response
  end

  describe "#parse_query" do

    it "returns an error for protocol error" do
      response = send_command("*1\r\n*1\r\nECHO\r\n")
      expect(response).to eq("-ERR protocol error\r\n")
    end

    it "returns an error for unknown command format" do
      response = send_command("#7\r\nUNKNOWN\r\n")
      expect(response).to eq("-ERR unknown command format\r\n")
    end
  end

  describe "#execute" do
    it "returns an error for unknown command" do
      response = send_command("*1\r\n$7\r\nUNKNOWN\r\n")
      expect(response).to eq("-ERR unknown command\r\n")
    end

    it "responds with +PONG for PING command" do
      response = send_command("*1\r\n$4\r\nPING\r\n")
      expect(response).to eq("+PONG\r\n")
    end

    it "responds with +OK for COMMAND DOCS" do
      response = send_command("*2\r\n$7\r\nCOMMAND\r\n$4\r\nDOCS\r\n")
      expect(response).to eq("+OK\r\n")
    end

    it "echoes back the argument for ECHO" do
      response = send_command("*2\r\n$4\r\nECHO\r\n$5\r\nHello\r\n")
      expect(response).to eq("$5\r\nHello\r\n")
    end

    it "returns an error when no argument is provided for ECHO" do
      response = send_command("*1\r\n$4\r\nECHO\r\n")
      expect(response).to eq("-ERR wrong number of arguments for 'echo' command\r\n")
    end

    it "sets a value to the given key using SET command" do
      response = send_command("*3\r\n$3\r\nSET\r\n$3\r\nfoo\r\n$3\r\nbar\r\n")
      expect(response).to eq("+OK\r\n")
    end

    it "gets the value to the given key using GET command" do
      send_command("*3\r\n$3\r\nSET\r\n$3\r\nkey\r\n$5\r\nvalue\r\n")
      response = send_command("*2\r\n$3\r\nGET\r\n$3\r\nkey\r\n")
      expect(response).to eq("$5\r\nvalue\r\n")
    end

    it "returns (nil) when given key is not present in redis" do
      response = send_command("*2\r\n$3\r\nGET\r\n$3\r\nbar\r\n")
      expect(response).to eq("$-1\r\n")
    end
  end
end
