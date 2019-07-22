# frozen_string_literal: true

class CreateGitHubRepoService
  class Exercise
    def self.build(assignment, collaborator)
      if collaborator.is_a?(User)
        IndividualExercise.new(assignment, collaborator)
      else
        GroupExercise.new(assignment, collaborator)
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

    def organization_login
      @organization_login ||= organization.github_organization.login
    end

    def assignment_type
      assignment.class.to_s.underscore
    end

    def user?
      is_a?(IndividualExercise)
    end

    def admin?
      assignment.students_are_repo_admins?
    end

    private

    def generate_repo_name
      suffix_count = 0

      loop do
        name = "#{organization_login}/#{suffixed_repo_name(suffix_count)}"
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
end
