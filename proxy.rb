# = Proxy
#
# A simple proxy server which forwards requests to a backend / another proxy.
#
# Start the proxy with command:
#
#   $ ruby proxy.rb
#
# Now connect to the internet via forwarded proxy:
#
#   $ curl --proxy1.0 localhost:9999 "http://example.com"
#

require 'rubygems'
require 'em-proxy'
require 'ansi/code'
require 'open-uri'

module Medusa

  PROXIES = [
    'http://82.119.76.144:80',
    'http://94.23.228.145:3128',
    'http://190.152.146.74:80'
  ]

  class Proxy

    attr_reader :url, :host, :port

    def initialize(url)
      @url = url
      parsed = URI.parse(@url)
      @host, @port = parsed.host, parsed.port
    end

    def self.select(method = :random)
      # TODO: balanced, ...
      # TODO: check status
      # self.new '127.0.0.1:5984'
      case method
        when :roundrobin
          @proxies = PROXIES.clone if @proxies.nil? || @proxies.empty?
          self.new @proxies.shift
        when :random
          self.new PROXIES[ rand(PROXIES.size-1) ]
        else
          raise ArgumentError, "Unknown proxy select method '#{method}'"
      end
    end

    alias :to_s :url

  end

  module Callbacks
    include ANSI::Code
    extend  self

    def on_data
      lambda do |data|
        puts black_on_yellow { 'on_data' } + ', request:', data
        data
      end
    end

    def on_response
      lambda do |name, resp|
        puts black_on_green { 'on_response' } + " from #{ bold { name } }, response:", resp
        resp
      end
    end

    def on_finish
      lambda do |name|
        puts black_on_magenta { 'on_finish' }, ''
      end
    end

  end

  module Server

    def start(host='0.0.0.0', port=9999)
      puts ANSI::Code.bold { "Launching proxy at #{host}:#{port}...\n" }

      ::Proxy.start(:host => host, :port => port, :debug => false) do |conn|

        proxy = Medusa::Proxy.select(:roundrobin)

        conn.server proxy, :host => proxy.host, :port => proxy.port

        conn.on_data     &Medusa::Callbacks.on_data
        conn.on_response &Medusa::Callbacks.on_response
        conn.on_finish   &Medusa::Callbacks.on_finish
      end
    end

    module_function :start
  end

end

Medusa::Server.start
