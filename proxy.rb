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
# or use the provided script, which sends multiple requests in one go:
#
#   $ ruby clients
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
    {'http://190.152.146.74:80' => 0},
    {'http://82.119.76.144:80'  => 0},
    {'http://67.208.112.173:80' => 0}
  ]

  $redis = Redis.new

  # Represents a "backend", ie. the endpoint for the proxy.
  #
  # This could be eg. a WEBrick webserver (see below), so the proxy server works as a _reverse_ proxy.
  # But it could also be a proxy server, so the proxy server works as a _forward_ proxy.
  #
  class Backend

    attr_reader :url, :host, :port, :strategy
    alias       :to_s :url

    def initialize(url)
      @url = url
      parsed = URI.parse(@url)
      @host, @port = parsed.host, parsed.port
    end

    # Select backend: balanced, round-robin or random
    #
    def self.select(strategy = :balanced)
      @strategy = strategy.to_sym
      case @strategy
        when :balanced
          backend = new list.sort { |a,b| a.values <=> b.values }.first.keys.first
        when :roundrobin
          @pool   = list.clone if @pool.nil? || @pool.empty?
          backend = new @pool.shift.keys.first
        when :random
          backend = new list[ rand(list.size-1) ].keys.first
        else
          raise ArgumentError, "Unknown strategy: #{@strategy}"
      end

      puts "---> Selecting #{backend}"
      backend.increment_counter if @strategy == :balanced
      yield backend if block_given?
      backend
    end

    # List of backends
    #
    def self.list
      @list ||= BACKENDS
    end

    # Increment "currently serving requests" counter
    #
    def increment_counter
      Backend.list.select { |b| b.keys.first == url }.first[url] += 1
    end

    # Decrement "currently serving requests" counter
    #
    def decrement_counter
      Backend.list.select { |b| b.keys.first == url }.first[url] -= 1
    end

  end

  # Callbacks for em-proxy events
  #
  module Callbacks
    include ANSI::Code
    extend  self

    def on_connect
      lambda do |backend|
        puts black_on_magenta { 'on_connect'.ljust(12) } + ' ' + bold { backend }
        $redis.incr "medusa>backends>#{backend}>total"
      end
    end

    def on_data
      lambda do |data|
        puts black_on_yellow { 'on_data'.ljust(12) }, data
        data
      end
    end

    def on_response
      lambda do |backend, resp|
        puts black_on_green { 'on_response'.ljust(12) } + " from #{backend}", resp
        resp
      end
    end

    def on_finish
      lambda do |backend|
        puts black_on_magenta { 'on_finish'.ljust(12) } + " for #{backend}", ''
        backend.decrement_counter if backend.strategy == :balanced
      end
    end

  end

  # Wrapping the proxy server
  #
  module Server
    def run(host='0.0.0.0', port=9999)

      puts ANSI::Code.bold { "Launching proxy at #{host}:#{port}...\n" }

      Proxy.start(:host => host, :port => port, :debug => false) do |conn|

        Backend.select do |backend|

          conn.server backend, :host => backend.host, :port => backend.port

          conn.on_connect  &Callbacks.on_connect
          conn.on_data     &Callbacks.on_data
          conn.on_response &Callbacks.on_response
          conn.on_finish   &Callbacks.on_finish
        end

      end
    end

    module_function :run
  end

end

Medusa::Server.run if __FILE__ == $0
