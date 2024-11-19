require_relative 'encode'

module Redis

  def self.configuration
    @configuration ||= Redis::Core::Configuration.new
  end
  def self.configure
    yield configuration if block_given?
  end

  module Core
    class Configuration
      attr_accessor :port, :host, :db_filename, :dir

      def initialize
        @port = 6379
        @host = '127.0.0.1'
        @db_filename = 'dump.rdb'
        @dir = '/tmp/redis'
      end
    end
  end
end




