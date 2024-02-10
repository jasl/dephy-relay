# frozen_string_literal: true

module NostrCable::Commands
  module Auth
    include NostrCable::Commands::Base

    class << self
      def schema_definition
        {
          "$schema": "http://json-schema.org/draft-07/schema#",
          id: "nostr/nips/01/commands/client/CLOSE/",
          type: "array",
          items: {
            id: "subscription_id",
            type: "string",
            minLength: 1,
            maxLength: 64
          },
          minItems: 1,
          maxItems: 1
        }
      end
    end
  end
end
