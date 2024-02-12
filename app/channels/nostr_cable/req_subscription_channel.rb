# frozen_string_literal: true

module NostrCable
  class ReqSubscriptionChannel < NostrCable::Channel
    def subscribed
      stream_from identifier
    end

    def transmit(data, via: nil) # :doc:
      logger.debug do
        status = "#{self.class.name} transmitting #{data.inspect.truncate(300)}"
        status += " (via #{via})" if via
        status
      end

      payload = { channel_class: self.class.name, data: data, via: via }
      ActiveSupport::Notifications.instrument("transmit.action_cable", payload) do
        connection.transmit data
      end
    end
  end
end
