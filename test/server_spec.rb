# tcp_spec.rb
require 'socket'
require 'rspec'

# Start the server in a separate thread
def start_server
  Thread.new do
    server = TCPServer.new('localhost', 6379)
    client = server.accept
    message = client.gets
    client.puts "Hello, client! You said: #{message}"
    client.close
  end
end

RSpec.describe "TCP Server and Client" do
  before(:all) do
    @server_thread = start_server
    sleep(1)  # Give the server a moment to start up
  end

  after(:all) do
    @server_thread.kill  # Stop the server after tests
  end

  it "sends and receives messages correctly" do
    client = TCPSocket.new('localhost', 2000)
    client.puts "Hello, server!"
    response = client.gets
    expect(response).to eq("Hello, client! You said: Hello, server!\n")
    client.close
  end
end
