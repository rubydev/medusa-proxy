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

include ANSI::Code

module Medusa
  class Proxy

    attr_reader :host, :port

    def initialize(options={})
      @host = options[:host]
      @port = options[:port]
    end

    def self.select
      self.new :host => '127.0.0.1', :port => '5984'
    end

  end
end

host, port = '0.0.0.0', '9999'
puts bold { "Launching proxy at #{host}:#{port}...\n" }

Proxy.start(:host => host, :port => port, :debug => false) do |conn|


  # 1. Select proxy
  # TODO: random, roundrobin, balanced, ...
  # TODO: check status
  proxy = Medusa::Proxy.select

  conn.server :srv, :host => proxy.host, :port => proxy.port

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
