module Medusa

  # Callbacks for em-proxy events
  #
  module Callbacks
    include ANSI::Code
    extend  self

    def on_select
      lambda do |backend|
        backend.increment_counter if Backend.strategy == :balanced
        $redis.incr "medusa>backends>#{backend}>current" if $redis
        if STDOUT.tty?
          puts black_on_white { 'on_select'.ljust(12) } + " #{backend.inspect}"
        end
      end
    end

    def on_connect
      lambda do |backend|
        $redis.incr "medusa>backends>#{backend}>total" if $redis
        if STDOUT.tty?
          puts black_on_magenta { 'on_connect'.ljust(12) } + ' ' + bold { backend.to_s.ljust(28) } + "| load: #{backend.load}"
        else
          Medusa.logger.debug "Connected to #{backend}"
        end
      end
    end

    def on_data
      lambda do |data|
        puts black_on_yellow { 'on_data'.ljust(12) }, data if STDOUT.tty?
        data
      end
    end

    def on_response
      lambda do |backend, resp|
        if STDOUT.tty?
          puts black_on_green { 'on_response'.ljust(12) } + " from #{backend}", resp
        else
          Medusa.logger.debug "Response with backend #{backend}: #{resp.sub(/\r\n.*$/m,"")}"
        end
        resp
      end
    end

    def on_finish
      lambda do |backend|
        backend.decrement_counter if Backend.strategy == :balanced
        $redis.decr "medusa>backends>#{backend}>current" if $redis
        if STDOUT.tty?
          puts black_on_magenta { 'on_finish'.ljust(12) } + " for #{backend.to_s.ljust(28)}" + "| load: #{backend.load}", ''
        else
          Medusa.logger.debug "Disconnected from #{backend}"
        end
      end
    end

  end

end
