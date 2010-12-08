module Medusa

  # Represents a "backend", ie. the endpoint for the proxy.
  #
  # This could be eg. a WEBrick webserver (see below), so the proxy server works as a _reverse_ proxy.
  # But it could also be a proxy server, so the proxy server works as a _forward_ proxy.
  #
  class Backend

    attr_reader   :url, :host, :port
    attr_accessor :load
    alias         :to_s :url

    def initialize(options={})
      raise ArgumentError, "Please provide a :url and :load" unless options[:url]
      @url   = options[:url]
      @load  = options[:load] || 0
      parsed = URI.parse(@url)
      @host, @port = parsed.host, parsed.port
    end

    # Select backend
    #
    # There are three possible stratgies to choose from:
    #
    # * <em>balanced</em>
    # * <em>round-robin</em>
    # * <em>random</em>
    #
    def self.select(strategy = :balanced)
      @strategy = strategy || :balanced
      case @strategy
        when :balanced
          backend = list.sort_by { |b| b.load }.first
        when :roundrobin
          @pool   = list.clone if @pool.nil? || @pool.empty?
          backend = @pool.shift
        when :random
          backend = list[ rand(list.size-1) ]
        else
          raise ArgumentError, "Unknown strategy: #{@strategy}"
      end

      Callbacks.on_select.call(backend)

      if backend.dead?
        backend = self.select(strategy)
      end

      yield backend if block_given?
      backend
    end

    # Return strategy for the Backend class
    #
    def self.strategy
      @strategy
    end

    # List of backends
    #
    def self.list
      @list ||= BACKENDS.map { |backend| new backend }
    end

    # Return balancing strategy
    #
    def self.strategy
      @strategy
    end

    # Increment "currently serving requests" counter
    #
    def increment_counter
      self.load += 1
    end

    # Decrement "currently serving requests" counter
    #
    def decrement_counter
      self.load -= 1
    end

    # Check if proxy is not on a death list
    #
    def dead?
      return false unless $redis
      $redis.sismember "medusa>backends>deathrow", url
    end

  end

end
