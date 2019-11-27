# frozen_string_literal: true

# Checks if classroom admins have access to the associated GitHub organization. If not
# the admin is removed from the classroom
task :remove_classroom_users_without_github_org_access, [:current_user] do |t, args|
    current_user = User.find_by(github_login: args[:current_user])
    github_org_ids = Organization.pluck(:github_id).uniq

    github_org_ids.each_slice(100) do |batch|
        batch.each do |gh_id|
            # test with 15126061 a multi classroom org
            classrooms = Organization.where(github_id: gh_id)
            classroom_admins = User.includes(:organizations).where(organizations: { id: classrooms.pluck(:id) })

            next unless classrooms.any? && classroom_admins.any?

            github_org = GitHubOrganization.new(current_user.github_client, gh_id)
            github_org = GitHubOrganization.new(classroom_admins.first.github_client, gh_id)

            classroom_admins.each do |user|
                next if github_org.admin?(user.github_user.login)
            end
        end
    end
end