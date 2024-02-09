# frozen_string_literal: true

module Api
  class ApplicationController < ActionController::API
    private

    def websocket?
      connection = request.env["HTTP_CONNECTION"] || ""
      upgrade    = request.env["HTTP_UPGRADE"]    || ""

      request.env["REQUEST_METHOD"] == "GET" &&
        connection.downcase.split(/ *, */).include?("upgrade") &&
        upgrade.downcase == "websocket"
    end
  end
end
