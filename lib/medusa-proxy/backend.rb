module Medusa

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

      puts "---> Selecting #{backend}" if STDOUT.tty?
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

end
