# frozen_string_literal: true

class CreateReqSubscriptions < ActiveRecord::Migration[7.2]
  def change
    create_table :req_subscriptions do |t|
      t.string :session_id, null: false
      t.string :subscription_id, null: false
      t.string :authors, array: true
      t.integer :kinds, array: true
      t.string :tags, array: true
      t.integer :since
      t.integer :until

      t.timestamps
    end
  end
end
