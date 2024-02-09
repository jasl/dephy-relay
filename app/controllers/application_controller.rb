# frozen_string_literal: true

class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  private

  def websocket?
    connection = request.env["HTTP_CONNECTION"] || ""
    upgrade    = request.env["HTTP_UPGRADE"]    || ""

    request.env["REQUEST_METHOD"] == "GET" &&
      connection.downcase.split(/ *, */).include?("upgrade") &&
      upgrade.downcase == "websocket"
  end
end
