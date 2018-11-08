# frozen_string_literal: true

class Group
  # Responsible for creating a Group and it's associated GitHub team.
  #
  class Creator
    class Result
      def self.success(group)
        new(:success, group: group)
      end

      def self.failed(error)
        new(:failed, error: error)
      end

      attr_reader :error, :group

      def initialize(status, group: nil, error: nil)
        @status = status
        @group  = group
        @error  = error
      end

      def success?
        @status == :success
      end

      def failed?
        @status == :failed
      end
    end

    def initialize(title:, grouping:)
      @title = title
      @grouping = grouping
    end

    # Public: Creates a Group and an associated GitHub team.
    #
    # title    - the team name to create a group for.
    # grouping - the grouping for the group to belong to.
    #
    # Example:
    #
    #   Group::Creator.perform(title "Octokittens", grouping: Grouping.first)
    #
    # Returns a Group::Creator::Result.
    def self.perform(title:, grouping:)
      new(title: title, grouping: grouping).perform
    end

    # Internal: Creates a Group and an associated GitHub team.
    #
    # Returns a Group::Creator::Result.
    def perform
      group = Group.new(title: @title, grouping: @grouping)
      group.create_github_team
      group.save!
      Result.success(group)
    rescue ActiveRecord::RecordInvalid, GitHub::Error => error
      group.silently_destroy_github_team
      Result.failed(error.message)
    end
  end
end
