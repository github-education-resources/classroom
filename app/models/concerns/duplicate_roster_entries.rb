# frozen_string_literal: true

module DuplicateRosterEntries
  extend ActiveSupport::Concern

  module ClassMethods
    def add_suffix_to_duplicates(identifiers:, existing_roster_entries: [])
      list_of_identifiers = []
      identifiers.each do |identifier|
        identifier = identifier.strip

        duplicates_found = (existing_roster_entries + list_of_identifiers).select do |entry|
          entry == identifier || entry.start_with?("#{identifier}-")
        end

        identifier = "#{identifier}-#{duplicates_found.count}" if duplicates_found.any?

        list_of_identifiers.push(identifier)
      end
      list_of_identifiers
    end
  end
  # rubocop:enable Metrics/MethodLength
end
