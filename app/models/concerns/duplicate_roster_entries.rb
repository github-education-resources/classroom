module DuplicateRosterEntries
  extend ActiveSupport::Concern

  module ClassMethods
    def add_suffix_to_duplicates(identifiers: [], roster_entries: [])
      list_of_identifiers = []
      identifiers.each do |identifier|
        identifier = identifier.strip

        duplicates_found = roster_entries.select do |entry|
          entry == identifier || entry.start_with?("#{identifier}-")
        end

        identifier = "#{identifier}-#{duplicates_found.count.to_s}" if duplicates_found.any?

        list_of_identifiers.push(identifier)
        roster_entries.push(identifier)
      end
      list_of_identifiers
    end
  end
end