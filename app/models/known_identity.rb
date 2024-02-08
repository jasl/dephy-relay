# frozen_string_literal: true

class KnownIdentity < ApplicationRecord
  normalizes :pubkey, with: ->(pubkey) { pubkey.strip.downcase }

  validates :pubkey,
            presence: true,
            uniqueness: true,
            length: { is: 64 },
            format: { with: /\A\h+\z/ }
end
