# frozen_string_literal: true

class CreateGitHubRepoService
  class Entity
    def self.build(assignment, collaborator)
      if collaborator.is_a?(User)
        Individual.new(assignment, collaborator)
      else
        Team.new(assignment, collaborator)
      end
    end

    attr_reader :assignment, :collaborator, :organization, :invite_status
    delegate :status, to: :invite_status

    def initialize(assignment, collaborator)
      @assignment = assignment
      @collaborator = collaborator
      @organization = assignment.organization
      @invite_status = assignment.invitation.status(collaborator)
    end

    def repo_name
      @repo_name ||= generate_repo_name
    end

    def default_repo_name
      "#{assignment.slug}-#{slug}"
    end

    def owner
      @owner ||= organization.github_organization.login_no_cache
    end

    def assignment_type
      assignment.class.to_s.underscore
    end

    def user?
      is_a?(Individual)
    end

    def admin?
      assignment.students_are_repo_admins?
    end

    private

    def generate_repo_name
      suffix_count = 0

      loop do
        name = "#{owner}/#{suffixed_repo_name(suffix_count)}"
        break unless GitHubRepository.present?(organization.github_client, name)

        suffix_count += 1
      end

      suffixed_repo_name(suffix_count)
    end

    def suffixed_repo_name(suffix_count)
      return default_repo_name if suffix_count.zero?

      suffix = "-#{suffix_count}"
      default_repo_name.truncate(100 - suffix.length, omission: "") + suffix
    end
  end

  class Individual < Entity
    def repos
      assignment.assignment_repos
    end

    def slug
      collaborator.github_user.login_no_cache
    end

    def humanize
      "user"
    end

    def stat_prefix
      "exercise_repo"
    end
  end

  class Team < Entity
    def repos
      assignment.group_assignment_repos
    end

    def slug
      collaborator.github_team.slug_no_cache
    end

    def humanize
      "group"
    end

    def stat_prefix
      "group_exercise_repo"
    end
  end
end
