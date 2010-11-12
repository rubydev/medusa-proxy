require 'rubygems'
require 'em-proxy'
require 'redis'
require 'ansi/code'
require 'open-uri'
require 'logger'

module Medusa

  BACKENDS = [
    {'http://190.152.146.74:80' => 0},
    {'http://82.119.76.144:80'  => 0},
    {'http://67.208.112.173:80' => 0}
  ]

  $redis = Redis.new

  def logger
    @logger ||= ::Logger.new(STDOUT)
  end
  module_function :logger

end

require 'medusa-proxy/backend'
require 'medusa-proxy/callbacks'
require 'medusa-proxy/server'

Medusa::Server.run if __FILE__ == $0
