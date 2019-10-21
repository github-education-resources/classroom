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
    byebug
    return nil unless instance_options[:roster]
    instance_options[:roster].roster_entries.find_by(user_id: object.user.id).identifier
  end
  # rubocop:enable MethodName
end
