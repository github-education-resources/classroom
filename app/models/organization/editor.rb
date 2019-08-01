# frozen_string_literal: true

class Organization
  class Editor
    attr_reader :users, :github_id

    class Result
      class Error < StandardError; end

      def self.success(organization)
        new(:success, organization: organization)
      end

      def self.failed(error)
        new(:failed, error: error)
      end

      attr_reader :error, :organization

      def initialize(status, organization: nil, error: nil)
        @status       = status
        @organization = organization
        @error        = error
      end

      def success?
        @status == :success
      end

      def failed?
        @status == :failed
      end
    end

    attr_reader :users

    # Public: Edit an Organization.
    #
    # organization - The Organization that is being edited.
    # options - The hash of attributes being edited on the ORganization.
    #
    # Returns an Organization::Editor::Result.
    def self.perform(organization:, options:)
      new(organization: organization, options: options).perform
    end

    def initialize(organization:, options:)
      @organization = organization
      @options = options
    end

    def perform
      update_archive_setting(@options)

      @organization.update_attributes(@options.except(:archived))
      raise Result::Error, @organization.errors.full_messages.join("\n") unless @organization.valid?

      Result.success(@organization)
    rescue Result::Error => err
      Result.failed(err.message)
    rescue GitHub::Error => err
      Result.failed(err.message)
    end

    private

    def update_archive_setting(options)
      archive = options[:archived]
      return if archive.nil?

      if archive == "true"
        @organization.update(archived_at: Time.zone.now)
      else
        @organization.update(archived_at: nil)
      end

      disable_invitations_in_all_assignments! if archive == "true"
    end

    def disable_invitations_in_all_assignments!
      classroom_assignments = @organization.assignments + @organization.group_assignments
      classroom_assignments.each do |assignment|
        assignment.update(invitations_enabled: false)
      end
    end
  end
end
