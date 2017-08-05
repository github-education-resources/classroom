# frozen_string_literal: true

class Assignment
  class Editor
    attr_reader :assignment, :options

    class Result
      class Error < StandardError; end

      def self.success(assignment)
        new(:success, assignment: assignment)
      end

      def self.failed(error)
        new(:failed, error: error)
      end

      attr_reader :error, :assignment

      def initialize(status, assignment: nil, error: nil)
        @status     = status
        @assignment = assignment
        @error      = error
      end

      def success?
        @status == :success
      end

      def failed?
        @status == :failed
      end
    end

    # Public: Edit an Assignment.
    #
    # assignment - The Assignment that is being edited.
    # options    - The Hash of attributes being edited on the assignment.
    #
    # Returns a Assignment::Editor::Result.
    def self.perform(assignment:, options:)
      new(assignment: assignment, options: options).perform
    end

    def initialize(assignment:, options:)
      @assignment = assignment
      @options    = options
    end

    # rubocop:disable AbcSize
    # rubocop:disable Metrics/MethodLength
    def perform
      recreate_deadline(@options[:deadline]) if deadline_updated_and_valid?

      @assignment.update_attributes(@options.except(:deadline))
      raise Result::Error, @assignment.errors.full_messages.join("\n") unless @assignment.valid?

      @assignment.previous_changes.each do |attribute, change|
        update_attribute_for_all_assignment_repos(attribute: attribute, change: change)
      end
      Result.success(@assignment)
    rescue Result::Error => err
      Result.failed(err.message)
    rescue GitHub::Error => err
      if no_private_repos_error?(err)
        @assignment.errors.add(:public_repo, "You have no private repositories available.")
      end

      Result.failed(err.message)
    end
    # rubocop:enable Metrics/MethodLength
    # rubocop:enable AbcSize

    private

    def recreate_deadline(deadline)
      @assignment.deadline&.destroy

      new_deadline(deadline) if deadline.present?
    end

    def new_deadline(deadline)
      new_deadline = Deadline::Factory.build_from_string(deadline_at: deadline)
      unless new_deadline.valid?
        @assignment.errors.add(:deadline, new_deadline.errors[:deadline_at].join("\n"))
        raise Result::Error
      end

      @assignment.deadline = new_deadline
      @assignment.deadline.create_job
      @assignment.save
    end

    def update_attribute_for_all_assignment_repos(attribute:, change:)
      case attribute
      when "public_repo"
        Assignment::RepositoryVisibilityJob.perform_later(@assignment, change: change)
      end
    end

    def deadline_updated_and_valid?
      return true if @options[:deadline].blank?

      new_deadline_at = DateTime.strptime(@options[:deadline], Deadline::Factory::DATETIME_FORMAT).utc
      new_deadline_at != @assignment.deadline&.deadline_at
    rescue ArgumentError
      false
    end

    def no_private_repos_error?(error)
      error.message.include? "Cannot make this private assignment, your limit of"
    end
  end
end
