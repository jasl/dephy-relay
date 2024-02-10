# frozen_string_literal: true

module NostrCable::Commands
  module Req
    include NostrCable::Commands::Base

    class << self
      def schema_definition
        {
          "$schema": "http://json-schema.org/draft-07/schema#",
          id: "nostr/nips/01/commands/client/REQ/",
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
                  items: {
                    type: "integer",
                    minimum: 0,
                    maximum: 65535
                  },
                  minLength: 1
                },
                "#e": {
                  id: "tagged_events",
                  type: "array",
                  items: {
                    type: "string",
                    minLength: 64, # Not part of NIP-11 but it doesn't make sense
                    maxLength: 64
                  }
                },
                "#p": {
                  id: "tagged_pubkeys",
                  type: "array",
                  items: {
                    type: "string",
                    minLength: 64, # Not part of NIP-11 but it doesn't make sense
                    maxLength: 64
                  }
                },
                since: {
                  id: "since",
                  type: "integer",
                  minimum: 0
                },
                until: {
                  id: "until",
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
          maxItems: 4 # RELAY_CONFIG.max_filters + 2
        }
      end

      def on_perform(handler, payloads)
        errors = []

        # we are confident its exactly filters here because we run this validation only if schema is correct
        filters = payloads[1..]
        filters.each_with_index do |filter_set, index|
          if filter_set["since"].present? && filter_set["until"].present? && filter_set["since"] > filter_set["until"]
            errors.push({
              field: "filters/#{index}/since-gt-until",
              message: "when both specified, until has always to be after since"
            })
          end
        end

        if errors.any?
          handler.transmit(
            "NOTICE",
            errors
              .map { |item| item[:field].present? ? "#{item[:field]}: #{item[:message]}" : item[:message] }
              .join("; ")
          )
          return
        end

        raise NotImplementedError
      end
    end
  end
end
