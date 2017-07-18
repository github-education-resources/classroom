# frozen_string_literal: true

module ShortKey
  extend ActiveSupport::Concern

  included do
    before_validation :assign_short_key, on: :create
  end

  def assign_short_key
    self.short_key ||= SecureRandom.urlsafe_base64(6).sub("+", "=")
  end
end
