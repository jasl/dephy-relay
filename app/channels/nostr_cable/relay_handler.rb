# frozen_string_literal: true

module NostrCable
  class RelayHandler
    KNOWN_COMMANDS = %w[REQ CLOSE EVENT COUNT AUTH]

    attr_reader :connection

    def initialize(connection)
      @connection = connection
    end

    delegate :logger, to: :connection

    def transmit(command, *args)
      connection.transmit [command, *args]
    end

    def perform(message)
      logger.info message.to_json

      unless message.is_a? Array
        transmit("NOTICE", "Invalid NoStr message")
        return
      end

      command = message[0]
      payload = message[1..]
      handler =
        case command
        when "AUTH"
          NostrCable::Commands::Auth
        when "COUNT"
          NostrCable::Commands::Count
        when "CLOSE"
          NostrCable::Commands::Close
        when "EVENT"
          NostrCable::Commands::Event
        when "REQ"
          NostrCable::Commands::Req
        else
          transmit("NOTICE", "Unrecognized NoStr command")
          return
        end

      handler.perform(self, payload)

      # TODO: process command
    end
  end
end
