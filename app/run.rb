require_relative 'server'

server = Redis::Server.new
server.start
