# frozen_string_literal: true

module NostrCable
  class Connection < ActionCable::Connection::Base
    attr_reader :last_active_at, :session_id

    identified_by :session_id

    def connect
      @session_id = "WS-#{SecureRandom.hex(4)}"
      @last_active_at = @started_at

      logger.add_tags @session_id
    end

    def disconnect
      # Any cleanup work needed when the cable connection is cut.
    end

    def close(reason:, message:)
      transmit([reason, message])
      websocket.close
    end

    def beat
      if Time.now - @last_active_at > 60.seconds
        close reason: "NOTICE", message: "Connection was idle for too long, max amount of time is 60 seconds"
      end
    end

    def dispatch_websocket_message(websocket_message) # :nodoc:
      unless websocket.alive?
        logger.error "Ignoring message processed after the WebSocket was closed: #{websocket_message.inspect})"
        return
      end

      @last_active_at = Time.now

      # TODO: check message size
      message =
        begin
          decode(websocket_message)
        rescue JSON::ParserError
          transmit(["NOTICE", "Malformed JSON"])
          return
        end
      run_callbacks :command do
        NostrCable::RelayHandler.new(self).perform(message)
      end
    end

    private

    def handle_open
      @protocol = websocket.protocol
      connect if respond_to?(:connect)
      subscribe_to_internal_channel

      message_buffer.process!
      server.add_connection(self)
    rescue ActionCable::Connection::Authorization::UnauthorizedError
      close(reason: "NOTICE", message: "Unauthorized") if websocket.alive?
    end
  end
end
