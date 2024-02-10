# frozen_string_literal: true

module NostrCable::Commands
  module Count
    include NostrCable::Commands::Base

    class << self
      def schema_definition
        {
          "$schema": "http://json-schema.org/draft-07/schema#",
          id: "nostr/nips/01/commands/client/COUNT/",
          type: "array",
          items: {
            id: "subscription_id",
            type: "string",
            minLength: 1,
            maxLength: 64
          },
          additionalItems: {
            "$ref": "#/definitions/filter_set"
          },
          definitions: {
            filter_set: {
              id: "filters/",
              type: "object",
              properties: {
                ids: {
                  id: "ids",
                  type: "array",
                  items: {
                    type: "string",
                    minLength: 64,
                    maxLength: 64
                  }
                },
                authors: {
                  id: "authors",
                  type: "array",
                  items: {
                    type: "string",
                    minLength: 64,
                    maxLength: 64
                  }
                },
                kinds: {
                  id: "kinds",
                  type: "array",
                  minLength: 1,
                  items: {
                    type: "integer",
                    minimum: 0
                  }
                },
                "#e": {
                  id: "tagged_events",
                  type: "array",
                  items: {
                    type: "string",
                    minLength: 64,
                    maxLength: 64
                  }
                },
                "#p": {
                  id: "tagged_pubkeys",
                  type: "array",
                  items: {
                    type: "string",
                    minLength: 64,
                    maxLength: 64
                  }
                },
                until: {
                  id: "until",
                  type: "integer",
                  minimum: 0
                },
                since: {
                  id: "since",
                  type: "integer",
                  minimum: 0
                },
                limit: {
                  id: "limit",
                  type: "integer",
                  minimum: 1
                }
              }
            }
          },
          minItems: 2,
          maxItems: 101 # RELAY_CONFIG.max_filters + 2
        }
      end
    end
  end
end
