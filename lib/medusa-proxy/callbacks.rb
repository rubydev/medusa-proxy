module Medusa

  # Callbacks for em-proxy events
  #
  module Callbacks
    include ANSI::Code
    extend  self

    def on_select
      lambda do |backend|
        if STDOUT.tty?
          puts black_on_white { 'on_select'.ljust(12) } + " #{backend.inspect}"
        end
        backend.increment_counter if Backend.strategy == :balanced
      end
    end

    def on_connect
      lambda do |backend|
        if STDOUT.tty?
          puts black_on_magenta { 'on_connect'.ljust(12) } + ' ' + bold { backend }
        else
          Medusa.logger.debug "Connected to #{backend}"
        end
        $redis.incr "medusa>backends>#{backend}>total"
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
        puts black_on_green { 'on_response'.ljust(12) } + " from #{backend}", resp if STDOUT.tty?
        resp
      end
    end

    def on_finish
      lambda do |backend|
        if STDOUT.tty?
          puts black_on_magenta { 'on_finish'.ljust(12) } + " for #{backend}", ''
        else
          Medusa.logger.debug "Disconnected from #{backend}"
        end
        backend.decrement_counter if Backend.strategy == :balanced
      end
    end

  end

end
