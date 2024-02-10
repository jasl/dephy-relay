# frozen_string_literal: true

module NostrCable::Commands
  module Event
    include NostrCable::Commands::Base

    class << self
      def schema_definition
        {
          "$schema": "http://json-schema.org/draft-07/schema#",
          id: "nostr/nips/01/commands/client/EVENT/",
          type: "array",
          items: {
            id: "event/",
            type: "object",
            properties: {
              id: {
                id: "id",
                type: "string",
                minLength: 64,
                maxLength: 64
              },
              pubkey: {
                id: "pubkey",
                type: "string",
                minLength: 64,
                maxLength: 64
              },
              created_at: {
                id: "created_at",
                type: "integer",
                minimum: 0
              },
              kind: {
                id: "kind",
                type: "integer",
                minimum: 0,
                maximum: 65535
              },
              tags: {
                id: "tags/",
                type: "array",
                items: {
                  type: "array",
                  prefixItems: {
                    type: "string",
                    minLength: 1
                  },
                  minLength: 1
                },
                maxItems: 16 # RELAY_CONFIG.max_event_tags
              },
              content: {
                id: "content",
                type: "string",
                maxLength: 8192 # RELAY_CONFIG.max_content_length
              },
              sig: {
                id: "sig",
                type: "string",
                minLength: 128,
                maxLength: 128
              }
            },
            required: %w[id pubkey created_at kind tags content sig]
          },
          minItems: 1,
          maxItems: 1
        }
      end

      def on_perform(handler, payloads)
        raw = payloads[0]
        subscription_id = raw["id"]
        unless subscription_id.present?
          handler.transmit "NOTICE", "Malformed EVENT"
          return
        end

        # Special handle `kind` here
        # TODO: this is a hack
        kind = raw["kind"]
        unless [1, 1111].include? kind
          handler.transmit "OK", subscription_id, false, "Unsupported `kind`"
          return
        end

        event = ::Event.from_raw(payloads[0])
        unless event.valid?
          # TODO: better error message
          handler.transmit "OK", subscription_id, false, event.errors.as_json
          return
        end

        begin
          event.save!
        rescue => ex
          handler.logger.error ex.message
          handler.transmit "OK", subscription_id, false, "Can't save"
          return
        end

        handler.transmit "OK", subscription_id, true, ""
      end
    end
  end
end
