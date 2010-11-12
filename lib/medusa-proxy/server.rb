module Medusa

  # Wrapping the proxy server
  #
  module Server
    def run(host='0.0.0.0', port=9999)

      if STDOUT.tty?
        puts ANSI::Code.bold { "Launching proxy at #{host}:#{port}...\n" }
      else
        Medusa.logger.info "Launching proxy at #{host}:#{port}...\n"
      end

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