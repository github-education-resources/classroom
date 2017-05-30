# frozen_string_literal: true

module Flippable
  extend ActiveSupport::Concern

  # Public: Check if an feature has been enabled for an
  # actor.
  #
  # flippable_feature - The Symbol name of the feature.
  #
  # Example:
  #
  #   current_user.feature_enabled?(student_identifier)
  #   # => false
  #
  # Returns a Boolean.
  def feature_enabled?(flippable_feature)
    GitHubClassroom.flipper[flippable_feature].enabled?(self)
  end

  def flipper_id
    "#{self.class}:#{id}"
  end
end
