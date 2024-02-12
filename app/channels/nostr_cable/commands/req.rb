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
          items: [
            {
              id: "subscription_id",
              type: "string",
              minLength: 1,
              maxLength: 64
            },
            {
              "$ref": "#/definitions/filter_set"
            }
          ],
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
          maxItems: 3 # RELAY_CONFIG.max_filters + 2
        }
      end

      def on_perform(handler, payloads)
        # we are confident its exactly filters here because we run this validation only if schema is correct
        subscription_id = payloads[0]
        if subscription_id.blank?
          handler.transmit(
            "NOTICE",
            "Invalid `subscription_id`"
          )
          return
        end

        errors = []
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

        # TODO: We only support one filter now

        # Store the subscription
        # it may disorder to push new event
        filters.each do |filter|
          ReqSubscription.create! session_id: handler.session_id,
                                  subscription_id: subscription_id,
                                  authors: filter["authors"],
                                  kinds: filter["kinds"],
                                  tags: filter["tags"],
                                  since: filter["since"],
                                  until: filter["until"]
          handler.session.subscribe(
            NostrCable::ReqSubscriptionChannel,
            "req_#{handler.session_id}_#{subscription_id}",
          )
        end

        # Do initial query
        queries =
          filters.map do |filter|
            query = ::Event.all
            if filter["authors"] && filter["authors"].any?
              query = query.where(pubkey: filter["authors"])
            end
            if filter["kinds"] && filter["kinds"].any?
              query = query.where(kind: filter["kinds"])
            end
            # TODO: tags
            if filter["since"]
              query = query.where("since >= ?", filter["since"].to_i)
            end
            if filter["until"]
              query = query.where("until < ?", filter["until"].to_i)
            end
            if filter["limit"]
              query = query.limit(filter["limit"].to_i || 50)
            end
            query
          end
        query =
          if queries.empty?
            ::Event.all
          elsif queries.size == 1
            queries.first
          else
            # I'm not sure this is correct
            q = ::Event
            queries.each do |sub|
              q = q.or(sub)
            end
            q
          end
        query.each do |event|
          handler.transmit("EVENT", subscription_id, event.raw_json)
        end
        handler.transmit("EOSE", subscription_id)
      end
    end
  end
end
