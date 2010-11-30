require 'rubygems'
require 'rest-client'
require 'em-proxy'
require 'redis'
require 'yajl'
require 'ansi/code'
require 'open-uri'
require 'logger'

require File.expand_path('../../config/config.rb', __FILE__)

module Medusa

  $redis = Redis.new rescue nil

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
