module Medusa

  # Represents a "backend", ie. the endpoint for the proxy.
  #
  # This could be eg. a WEBrick webserver (see below), so the proxy server works as a _reverse_ proxy.
  # But it could also be a proxy server, so the proxy server works as a _forward_ proxy.
  #
  class Backend

    attr_reader   :url, :host, :port, :strategy
    attr_accessor :load
    alias         :to_s :url

    def initialize(options={})
      raise ArgumentError, "Please provide a :url and :load" unless options[:url]
      @url   = options[:url]
      @load  = options[:load] || 0
      parsed = URI.parse(@url)
      @host, @port = parsed.host, parsed.port
    end

    # Select backend: balanced, round-robin or random
    #
    def self.select(strategy = :balanced)
      @strategy = strategy.to_sym
      case @strategy
        when :balanced
          # backend = new list.sort { |a,b| a.values <=> b.values }.first.keys.first
          backend = list.sort_by { |b| b.load }.first
        when :roundrobin
          @pool   = list.clone if @pool.nil? || @pool.empty?
          backend = @pool.shift
        when :random
          backend = list[ rand(list.size-1) ]
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
      @list ||= BACKENDS.map { |backend| new backend }
    end

    # Increment "currently serving requests" counter
    #
    def increment_counter
      # Backend.list.select { |b| b.keys.first == url }.first[url] += 1
      self.load += 1
    end

    # Decrement "currently serving requests" counter
    #
    def decrement_counter
      # Backend.list.select { |b| b.keys.first == url }.first[url] -= 1
      self.load -= 1
    end

  end

end
