# frozen_string_literal: true

class Roster
  class Creator
    class Result
      class Error < StandardError; end

      def self.success(roster)
        new(:success, roster: roster)
      end

      def self.failed(roster, error)
        new(:failed, roster: roster, error: error)
      end

      attr_reader :error, :roster

      def initialize(status, roster: nil, error: nil)
        @status = status
        @roster = roster
        @error  = error
      end

      def success?
        @status == :success
      end

      def failed?
        @status == :failed
      end
    end

    # Public: Create a Roster for an Organiation.
    #
    # organization    - The Organization the Roster will belong to.
    # identifier_name - The name of the identifiers for the Roster.
    # options         - The Hash of options.
    #
    # Examples
    #
    #   Roster::Creator.perform(
    #     organization: current_organization,
    #     identifier_name: "Email",
    #     options
    #   )
    #
    # Returns an Roster::Creator::Result.
    def self.perform(organization:, identifier_name:, **options)
      new(organization: organization, identifier_name: identifier_name, **options).perform
    end

    def initialize(organization:, identifier_name:, **options)
      @organization    = organization
      @identifier_name = identifier_name
      @options         = options
    end

    # Internal: Create create a Roster.
    #
    def perform
      ensure_organization_does_not_have_roster!

      ActiveRecord::Base.transaction do
        @roster = Roster.new(identifier_name: @identifier_name)

        if @options.key?(:identifiers)
          add_identifiers_to_roster(@options[:identifiers], google_user_ids: @options[:google_user_ids]) if @options.key?(:google_user_ids)
        else
          add_identifiers_to_roster(@options[:identifiers]) if @options.key?(:google_user_ids)
        end

        @roster.save!
        @organization.update_attributes!(roster: @roster)
      end

      Result.success(@roster)
    rescue Result::Error, ActiveRecord::ActiveRecordError => err
      Result.failed(@roster, err.message)
    end

    private

    def add_identifiers_to_roster(raw_identifiers_string, google_user_ids: [])
      identifiers = raw_identifiers_string.split("\r\n").reject(&:blank?).uniq

      identifiers.zip(google_user_ids).each do |identifier, google_user_id|
        @roster.roster_entries << RosterEntry.new(identifier: identifier, google_user_id: google_user_id)
      end
    end

    def ensure_organization_does_not_have_roster!
      raise Result::Error, "This organization already has a roster" unless @organization.roster.nil?
    end
  end
end
