# = A simple reverse/forward proxy
#
# A simple proxy which forwards requests to a backend / another proxy.
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

include ANSI::Code

module Medusa

  PROXIES = [
    'http://94.23.228.145:3128',
    'http://82.119.76.144:80',
    'http://190.152.146.74:80'
  ]

  class Proxy

    attr_reader :url, :host, :port

    def initialize(url)
      @url = url
      parsed = URI.parse(@url)
      @host, @port = parsed.host, parsed.port
    end

    def self.select
      # TODO: random, roundrobin, balanced, ...
      # TODO: check status
      # self.new '127.0.0.1:5984'
      self.new PROXIES[ rand(PROXIES.size-1) ]
    end

    alias :to_s :url

  end
end

host, port = '0.0.0.0', '9999'
puts bold { "Launching proxy at #{host}:#{port}...\n" }

Proxy.start(:host => host, :port => port, :debug => false) do |conn|

  proxy = Medusa::Proxy.select

  conn.server proxy, :host => proxy.host, :port => proxy.port

  conn.on_data do |data|
    puts black_on_yellow { 'on_data' } + ', request:'
    puts data
    data
  end

  conn.on_response do |backend, resp|
    puts black_on_green { 'on_response' } + " from #{ bold { backend } }, response:"
    puts resp
    resp
  end

  conn.on_finish do |backend, name|
    puts black_on_magenta { 'on_finish' }
    unbind if backend == :srv
  end

end
