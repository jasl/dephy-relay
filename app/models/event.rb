# frozen_string_literal: true

class Event < ApplicationRecord
  include Nostr::Nip1

  class << self
    def from_raw(message)
      return new unless message

      new(
        uid: message.fetch("id"),
        pubkey: message.fetch("pubkey"),
        created_at: message.fetch("created_at"),
        kind: message.fetch("kind"),
        tags: message.fetch("tags"),
        content: message.fetch("content"),
        sig: message.fetch("sig")
      )
    end
  end
end
