# frozen_string_literal: true

require "async/websocket/adapters/rack"

module Api
  class HomeController < Api::ApplicationController
    def index
      render json: {
        status: "ok"
      }
    end

    def nostr
      if websocket?
        process_websocket and return
      end

      render json: {
        status: "ok"
      }
    end

    private

    def process_websocket
      self.response = ActionDispatch::Response.new(
        *Async::WebSocket::Adapters::Rack.open(request.env) do |connection|
          connection.write({ message: "Hello World" })
        end
      )
    end
  end
end
