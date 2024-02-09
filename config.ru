# frozen_string_literal: true

# This file is used by Rack-based servers to start the application.

require_relative "config/environment"

# def websocket?(env)
#   connection = env["HTTP_CONNECTION"] || ""
#   upgrade    = env["HTTP_UPGRADE"]    || ""
#
#   env["REQUEST_METHOD"] == "GET" &&
#     connection.downcase.split(/ *, */).include?("upgrade") &&
#     upgrade.downcase == "websocket"
# end
#
# require "async/websocket/adapters/rack"
# websocket_server = lambda do |env|
#   Async::WebSocket::Adapters::Rack.open(env) do |connection|
#     while (message = connection.read)
#       connection.write message
#     end
#   end
# end
#
# both_apps = lambda do |env|
#   if websocket?(env) || env["HTTP_ACCEPT"] == "application/nostr+json"
#     websocket_server.call(env)
#   else
#     Rails.application.call(env)
#   end
# end
#
# # run Rails.application
# run both_apps

run Rails.application
Rails.application.load_server
