require_relative 'server'

require 'optparse'

options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: server.rb [options]"

  opts.on("--dir DIR", "Specify the directory name") do |dir|
    options[:dir] = dir
  end

  opts.on("--dbfilename DBFILE", "Specify the database file name") do |dbfile|
    options[:dbfilename] = dbfile
  end

  opts.on("-p port", "Specify the port number") do |port|
    options[:port] = port
  end
end.parse!

server = Redis::Server.new(port: options[:port], dir: options[:dir], dbfilename: options[:dbfilename])
server.start
