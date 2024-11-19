require "socket"
require "rspec"

require_relative "../app/server"

RSpec.describe Redis::Server do
  let(:port) { 6381 }
  let(:server) { described_class.new(port: port) }
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
    context "when known command is provided" do
      [
        { input: ["PING"], expected_output: "+PONG\r\n" },
        { input: ["ECHO"], expected_output: "-ERR wrong number of arguments for 'echo' command\r\n" },
        { input: %w[ECHO HEY!!], expected_output: "$5\r\nHEY!!\r\n" },
      ].each do |test_case|
        it "returns '#{test_case[:expected_output]}' given input '#{test_case[:input].join(' ')}'" do
          response = server.execute(test_case[:input])
          expect(response).to eq(test_case[:expected_output])
        end
      end
    end

    context "when unknown command is provided" do
      [{ input: ["UNKNOWN"], expected_output: "-ERR unknown command\r\n" }].each do |test_case|
        it "returns '#{test_case[:expected_output]}' given input '#{test_case[:input].join(' ')}'" do
          response = server.execute(test_case[:input])
          expect(response).to eq(test_case[:expected_output])
        end
      end
    end
  end

end
