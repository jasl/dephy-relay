# frozen_string_literal: true

class CreateKnownIdentities < ActiveRecord::Migration[7.2]
  def change
    create_table :known_identities do |t|
      t.string :pubkey, null: false, index: { unique: true }
      t.datetime :created_at, null: false
    end
  end
end
