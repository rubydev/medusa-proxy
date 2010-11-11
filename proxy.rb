# = Proxy
#
# A simple, balanced proxy server which forwards requests to a backend / another proxy.
#
# Start the proxy with command:
#
#   $ ruby proxy.rb
#
# Now connect to the internet via forwarded proxy:
#
#   $ curl --proxy1.0 localhost:9999 "http://example.com"
#
#
# == TODO:
#
# * Implement health check for proxies (asynchronically? perform union of sorted set with healthy proxies set?)
# * Gemify
# * Daemonize
# * Tests
#

require 'rubygems'
require 'em-proxy'
require 'redis'
require 'ansi/code'
require 'open-uri'

module Medusa

  BACKENDS = [
    'http://80.79.23.179:8080',
    'http://94.23.228.145:3128',
    'http://190.152.146.74:80'
  ]

  $redis = Redis.new
  $redis.del "medusa>backends>connections"
  BACKENDS.each_with_index { |proxy, score| $redis.zadd "medusa>backends>connections", score, proxy }

  class Backend

    attr_reader :url, :host, :port

    def initialize(url)
      @url = url
      parsed = URI.parse(@url)
      @host, @port = parsed.host, parsed.port
    end

    def self.select(method = :random)
      case method
        when :balanced
          backend = new $redis.zrank("medusa>backends>connections", 0, 0).first
        when :roundrobin
          @backends = BACKENDS.clone if @backends.nil? || @backends.empty?
          backend = new @backends.shift
        when :random
          backend = new BACKENDS[ rand(BACKENDS.size-1) ]
        else
          raise ArgumentError, "Unknown backend select method '#{method}'"
      end
      yield backend if block_given?
      backend
    end

    alias :to_s :url

  end

  module Callbacks
    include ANSI::Code
    extend  self

    def on_connect
      lambda do |name|
        puts black_on_magenta { 'on_connect'.ljust(12) } + ' ' + bold { name }
        $redis.incr "medusa>backends>#{name}>total"
        $redis.zincrby "medusa>backends>connections", 1, name
      end
    end

    def on_data
      lambda do |data|
        puts black_on_yellow { 'on_data'.ljust(12) }, data
        data
      end
    end

    def on_response
      lambda do |name, resp|
        puts black_on_green { 'on_response'.ljust(12) }, resp
        resp
      end
    end

    def on_finish
      lambda do |name|
        puts black_on_magenta { 'on_finish'.ljust(12) }, ''
        $redis.zincrby "medusa>backends>connections", -1, name
      end
    end

  end

  module Server

    def start(host='0.0.0.0', port=9999)

      puts ANSI::Code.bold { "Launching proxy at #{host}:#{port}...\n" }

      Proxy.start(:host => host, :port => port, :debug => false) do |conn|

        proxy = Medusa::Backend.select(:roundrobin) do |proxy|

          conn.server proxy, :host => proxy.host, :port => proxy.port

          conn.on_connect  &Medusa::Callbacks.on_connect
          conn.on_data     &Medusa::Callbacks.on_data
          conn.on_response &Medusa::Callbacks.on_response
          conn.on_finish   &Medusa::Callbacks.on_finish
        end

      end
    end

    module_function :start
  end

end

Medusa::Server.start
