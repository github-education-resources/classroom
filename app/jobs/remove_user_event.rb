# Documentation: https://developer.github.com/v3/activity/events/types/#membershipevent
class RemoveUserJob < ApplicationJob
  queue_as :github_event
  def perform(payload)
    return true unless payload_body.dig('action') == 'removed'

    github_user_id = payload_body.dig('member', 'id')
    github_organization_id = payload_body.dig('organization','id')

    organization = Organization.find_by(github_id: github_organization_id)
    organization.users.delete(github_id: github_user_id)
    organization.save
  end
end
