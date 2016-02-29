module Flippable
  extend ActiveSupport::Concern

  def flipper_id
    "#{self.class}:#{id}"
  end
end
