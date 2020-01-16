# frozen_string_literal: true

# Checks if classroom admins have access to the associated GitHub organization. If not
# the admin is removed from the classroom
task :remove_classroom_users_without_github_org_access do
  User.find_in_batches(batch_size: 250).with_index do |group, batch|
    puts "Processing batch ##{batch}"
    group.each do |user|
      github_org_ids = user.organizations.pluck(:github_id).uniq
      next unless github_org_ids.any?

      github_org_ids.each do |gh_id|
        github_org = GitHubOrganization.new(user.github_client, gh_id)
        next if github_org.admin?(user.github_login)

        payload = {
          "action": "member_removed",
          "membership": { "user": { "id": user.github_user.id } },
          "organization": { "id": gh_id }
        }

        puts "Removing #{user.github_login} from org with id ##{gh_id}"
        OrganizationEventJob.perform_later(payload)
      end
    end
  end
end
