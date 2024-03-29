# frozen_string_literal: true

module Nostr
  module Nip1
    # AVAILABLE_FILTERS = SubscriptionQueryBuilder::AVAILABLE_FILTERS.map { |filter_name| /\A[a-zA-Z]\Z/.match?(filter_name) ? "##{filter_name}" : filter_name }

    KNOWN_KIND_TYPES = {
      text_note: 1,
      dephy_message: 1111
    }

    extend ActiveSupport::Concern

    included do
      normalizes :uid, with: ->(uid) { uid.strip.downcase }
      normalizes :pubkey, with: ->(pubkey) { pubkey.strip.downcase }
      normalizes :sig, with: ->(sig) { sig.strip.downcase }

      validates :uid,
                presence: true,
                uniqueness: true,
                length: { is: 64 },
                format: { with: /\A\h+\z/ }
      validates :pubkey,
                presence: true,
                uniqueness: true,
                length: { is: 64 },
                format: { with: /\A\h+\z/ }
      validates :kind,
                presence: true,
                inclusion: {
                  in: KNOWN_KIND_TYPES.values
                }
      validates :content,
                presence: true
      validates :sig,
                presence: true,
                length: { is: 128 },
                format: { with: /\A\h+\z/ }
      validate :id_must_match_payload
      validate :sig_must_match_payload

      after_create :broadcast_to_subscriptions

      def created_at=(value)
        value.is_a?(Numeric) ? super(Time.at(value)) : super(value)
      end

      def serialized_nostr_event
        [
          0,
          pubkey,
          created_at.to_i,
          kind,
          tags,
          content.to_s
        ]
      end

      def serialized_nostr_event_json
        serialized_nostr_event.to_json
      end

      def raw_json
        {
          kind:,
          content:,
          pubkey:,
          sig:,
          created_at: created_at.to_i,
          id: uid,
          tags: tags
        }.to_json
      end

      def computed_uid
        Digest::SHA256.hexdigest(serialized_nostr_event_json)
      end

      def schnorr_signature_verified?
        schnorr_params = {
          message: [uid].pack("H*"),
          pubkey: [pubkey].pack("H*"),
          sig: [sig].pack("H*")
        }
        Secp256k1::SchnorrSignature.from_data(schnorr_params[:sig])
                                   .verify(
                                     schnorr_params[:message],
                                     Secp256k1::XOnlyPublicKey.from_data(schnorr_params[:pubkey])
                                   )
      rescue Secp256k1::DeserializationError => _ex
        false
      end

      private

      def id_must_match_payload
        unless computed_uid == uid
          errors.add(:uid, "must match payload")
        end
      end

      def sig_must_match_payload
        unless schnorr_signature_verified?
          errors.add(:sig, "must match payload")
        end
      end

      def subscriptions
        ReqSubscription
          .where("? = ANY (authors)", pubkey).or(ReqSubscription.where(authors: nil))
          .where("? = ANY (kinds)", kind).or(ReqSubscription.where(kinds: nil))
          .where("since < ?", created_at.to_i).or(ReqSubscription.where(since: nil))
          .where("until > ?", created_at.to_i).or(ReqSubscription.where(until: nil))
          .where("updated_at < ?", created_at)
      end

      def broadcast_to_subscriptions
        subscriptions.each do |s|
          ActionCable.nostr_server.broadcast "req_#{s.session_id}_#{s.subscription_id}",
                                             [
                                               "EVENT",
                                               s.subscription_id,
                                               raw_json
                                             ]
        end
      end
    end
  end
end
