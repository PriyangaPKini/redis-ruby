require_relative 'server'

require 'optparse'

options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: script.rb [options]"

  opts.on("--dir DIR", "Specify the directory name") do |dir|
    options[:dir] = dir
  end

  opts.on("--dbfilename DBFILE", "Specify the database file name") do |dbfile|
    options[:db_filename] = dbfile
  end
end.parse!

server = Redis::Server.new(port: 6380, dir: options[:dir], db_filename: options[:db_filename])
server.start
