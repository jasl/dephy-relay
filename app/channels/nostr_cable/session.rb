# frozen_string_literal: true

module NostrCable
  class Session
    attr_reader :connection, :session_id, :alive
    delegate :logger, to: :connection, allow_nil: false

    def initialize(connection, session_id)
      @connection = connection
      @session_id = session_id
      @alive = true
    end

    def alive?
      @alive
    end

    def subscribe(subscription_klass, id_key, id_options = {})
      raise "Session has ended" unless alive?
      raise "`id_key` must not blank" if id_key.blank?
      return if subscriptions.key?(id_key)

      subscription = subscription_klass.new(connection, id_key, id_options)
      subscriptions[id_key] = subscription
      subscription.subscribe_to_channel
    end

    def unsubscribe(id_key)
      raise "Session has ended" unless alive?
      raise "`id_key` must not blank" if id_key.blank?

      subscription = subscriptions[id_key]
      raise "Unable to find subscription with identifier: #{id_key}" unless subscription

      connection.subscriptions.remove_subscription(subscription)
    end

    def destroy!
      raise "Session has ended" unless alive?

      ReqSubscription.where(session_id: @session_id).delete_all
      connection.subscriptions.unsubscribe_from_all

      @alive = false
    end

    private

    def subscriptions
      # Hack to avoid modify it
      connection.subscriptions.instance_variable_get(:@subscriptions)
    end
  end
end
