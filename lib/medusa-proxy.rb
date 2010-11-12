require 'rubygems'
require 'rest-client'
require 'em-proxy'
require 'redis'
require 'yajl'
require 'ansi/code'
require 'open-uri'
require 'logger'

module Medusa

  PROXY_LIST_URL = 'https://user:password@example.com/private/resource'

  $redis = Redis.new

  def logger
    @logger ||= ::Logger.new(STDOUT)
  end
  module_function :logger

end

require 'medusa-proxy/config'
require 'medusa-proxy/backend'
require 'medusa-proxy/callbacks'
require 'medusa-proxy/server'

Medusa::Server.run if __FILE__ == $0
