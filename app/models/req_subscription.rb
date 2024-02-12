# frozen_string_literal: true

class ReqSubscription < ApplicationRecord
  validates :session_id,
            presence: true
  validates :subscription_id,
            presence: true
end
