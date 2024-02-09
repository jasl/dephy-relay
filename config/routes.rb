# frozen_string_literal: true

Rails.application.routes.draw do
  namespace :api do
    root to: "home#index"

    get "nostr" => "home#nostr"
  end

  root to: "home#index"

  mount ActionCable.server => "/ws", internal: true, anchor: true

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # ActiveJob visualizer
  mount MissionControl::Jobs::Engine, at: "/jobs"

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/*
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest

  # Defines the root path route ("/")
  # root "posts#index"
end
