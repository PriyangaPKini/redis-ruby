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

    it "returns an error for unknown command" do
      response = send_command("*1\r\n$7\r\nUNKNOWN\r\n")
      expect(response).to eq("-ERR unknown command\r\n")
    end

    it "returns an error for protocol error" do
      response = send_command("*1\r\n*1\r\nECHO\r\n")
      expect(response).to eq("-ERR protocol error\r\n")
    end
  end
end
