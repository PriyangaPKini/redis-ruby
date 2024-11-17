require_relative 'server'

server = Redis::Server.new(6379)
server.start
