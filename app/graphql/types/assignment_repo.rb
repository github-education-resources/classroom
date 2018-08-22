require_relative "../loaders/github_loader"

class Types
  class AssignmentRepo < GraphQL::Schema::Object
    require_relative "user"
    require_relative "assignment"

    # To see an assignment repo, you must be an admin on the organization
    def self.authorized?(repo, context)
      super && context[:current_user] && repo.assignment.organization.users.include?(context[:current_user])
    end

    global_id_field :id

    field :assignment, Types::Assignment, description: "The assignment repo assignment", null: false

    field :submission_sha, String, description: "The submission sha for the assignment repo.", null: true

    field :submission_url, String, description: "The GitHub tree URL for the submission sha, if present.", null: true

    def submission_url
      return unless object.submission_sha

      GitHubLoader.load_on_relay_node(object.github_global_relay_id, "Repository", "url", context: context).then do |results|
        "#{results.dig("data", "node", "url")}/commit/#{object.submission_sha}"
      end
    end

    field :repository_url, String, description: "The repository URL", null: false

    # TODO: Abstract this pattern into a helper
    def repository_url
      GitHubLoader.load_on_relay_node(object.github_global_relay_id, "Repository", "url", context: context).then do |results|
        results.dig("data", "node", "url")
      end
    end

    CommitCountFragment = <<-GRAPHQL
      defaultBranchRef{
        target{
          ... on Commit{
            history{
              totalCount
            }
          }
        }
      }
    GRAPHQL

    field :commit_count, Integer, description: "The number of commits the student has made.", null: false

    def commit_count
      GitHubLoader.load_on_relay_node(object.github_global_relay_id, "Repository", CommitCountFragment, context: context).then do |results|
        if results.dig("data", "node", "default_branch_ref")
          results.dig("data", "node", "default_branch_ref", "target", "history", "total_count")
        else
          0
        end
      end
    end

    field :user, Types::User, description: "The user owning the assignment repo.", null: false
  end
end
