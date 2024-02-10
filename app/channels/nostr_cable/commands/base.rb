# frozen_string_literal: true

module NostrCable::Commands
  module Base
    extend ActiveSupport::Concern

    module ClassMethods
      def schema_definition
        raise NotImplementedError
      end

      def schema
        @schema ||= JSONSchemer.schema(schema_definition.to_json)
      end

      def validate_schema(payloads)
        errors = []

        schema.validate(payloads).each do |error|
          errors.push({ field: error["data_pointer"], message: JSONSchemer::Errors.pretty(error) })
        end

        errors
      end

      def perform(handler, payloads)
        errors = validate_schema(payloads)
        if errors.any?
          handler.transmit(
            "NOTICE",
            errors
              .map { |item| item[:field].present? ? "#{item[:field]}: #{item[:message]}" : item[:message] }
              .join("; ")
          )
          return
        end

        on_perform(handler, payloads)
      end

      def on_perform(_handler, _payloads)
        raise NotImplementedError
      end
    end
  end
end
