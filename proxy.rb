#!/usr/bin/env ruby

require 'rubygems'
require 'em-proxy'

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

Proxy.start(:host => "0.0.0.0", :port => 9999, :debug => false) do |conn|

  # 1. Select proxy
  # TODO: random, roundrobin, balanced, ...
  # TODO: check status
  proxy = Medusa::Proxy.select

  conn.server :srv, :host => proxy.host, :port => proxy.port

  conn.on_data do |data|
    p [:on_data, data]
    data
  end

  conn.on_response do |backend, resp|
    p [:on_response, backend, resp]
    resp
  end

  conn.on_finish do |backend, name|
    p [:on_finish, name]
    unbind if backend == :srv
  end
end
