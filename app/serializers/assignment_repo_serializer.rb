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
    return nil unless instance_options[:roster_entries].present?

    roster_entry = instance_options[:roster_entries].find{ |roster_entry| roster_entry.user_id == object.user.id }
    roster_entry&.identifier
  end
  # rubocop:enable MethodName
end
