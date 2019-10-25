# frozen_string_literal: true

class AssignmentRepoSerializer < ActiveModel::Serializer
  attributes :id
  attributes :username
  attributes :displayName
  attributes :rosterIdentifier

  def username
    object.user.github_user.login
  end

  # rubocop:disable MethodName
  def displayName
    object.user.github_user.name || ""
  end

  def rosterIdentifier
    return nil if instance_options[:roster_entries].blank?

    roster_entry = instance_options[:roster_entries].find { |entry| entry.user_id == object.user.id }
    roster_entry&.identifier
  end
  # rubocop:enable MethodName
end
